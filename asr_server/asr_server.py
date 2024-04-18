#!/usr/bin/env python3

import json
import os
import sys
import asyncio
import pathlib
import websockets
import concurrent.futures
import logging
from vosk import Model, SpkModel, KaldiRecognizer

def process_chunk(rec, message):
    if type(message) is str:
        jobj = json.loads(message)
        if 'eof' in jobj and jobj['eof'] == True:
            return rec.FinalResult(), True
        if 'reset' in jobj and jobj['reset'] == True:            
            return rec.FinalResult(), False
        return None, False
    elif rec.AcceptWaveform(message):
        return rec.Result(), False
    else:
        return rec.PartialResult(), False

def process_chunk2(rec, message, rec_config):
    logging.debug(f'Got chunk {type(message)} ')
    if type(message) is str:
        if 'uuid' in message:
            pass
        elif 'grammar' in message:
            logging.debug(f"Grammar request '{message}'")                
            grammar = json.loads(message)
            prompt_grammar = grammar['grammar']
            logging.debug(f"Using grammar: {prompt_grammar}")                
        elif 'eof' in message: # VoiceGW indicator of end
            logging.info(rec.FinalResult())
            final_res=rec.FinalResult()  
            return final_res, True
    elif type(message) is bytes:
        logging.debug(f'Got audio chunk of {len(message)} bytes')
        if rec.AcceptWaveform(message): # Digest VoiceGW audio      
            partial_res=rec.Result()
        else:
            partial_res = rec.PartialResult()    
        logging.debug(f"Partial result: {partial_res}")
        if rec_config.partial_results:
            return partial_res, False
    return None, False

async def recognize2(websocket, path):
    global model
    global spk_model
    global args
    global pool

    loop = asyncio.get_running_loop()
    rec = None
    rec_config = type('',(),{})
    rec_config.phrase_list= None,
    rec_config.sample_rate= args.sample_rate,
    rec_config.show_words= args.show_words,
    rec_config.max_alternatives= args.max_alternatives,
    rec_config.partial_results= False
    

    logging.info('Connection from %s', websocket.remote_address);
    prompt_grammar = None
    while True:
        try:
            message = await websocket.recv()
            if isinstance(message, str):
                # Load configuration if provided            
                if 'config' in message:
                    jobj = json.loads(message)['config']
                    logging.info("Config %s", jobj)
                    if 'phrase_list' in jobj:
                        rec_config.phrase_list = jobj['phrase_list']
                    if 'sample_rate' in jobj:
                        rec_config.sample_rate = float(jobj['sample_rate'])
                    if 'model' in jobj:
                        model = Model(jobj['model'])
                        model_changed = True
                    if 'words' in jobj:
                        rec_config.show_words = bool(jobj['words'])
                    if 'max_alternatives' in jobj:
                        rec_config.max_alternatives = int(jobj['max_alternatives'])
                    if 'partial_results' in jobj:
                        rec_config.partial_results = jobj['partial_results']
                continue

            # Create the recognizer, word list is temporary disabled since not every model supports it
            if not rec or model_changed:
                model_changed = False
                if rec_config.phrase_list:
                    rec = KaldiRecognizer(model, rec_config.sample_rate, json.dumps(rec_config.phrase_list, ensure_ascii=False))
                else:
                    rec = KaldiRecognizer(model, rec_config.sample_rate)
                rec.SetWords(rec_config.show_words)
                rec.SetMaxAlternatives(rec_config.max_alternatives)
                if spk_model:
                    rec.SetSpkModel(spk_model)

            response, stop = await loop.run_in_executor(pool, process_chunk, rec, message, rec_config)
            if response is not None:
                await websocket.send(response)
            
        except asyncio.exceptions.IncompleteReadError as e1:
            logging.error(f"End of Stream found during speech-to-text conversion:{e1}")
            pass
        except Exception as e:
            logging.error(f"Error during speech-to-text conversion:{e}")
            stop = websocket.closed

        if stop: break

async def recognize(websocket, path):
    global model
    global spk_model
    global args
    global pool

    loop = asyncio.get_running_loop()
    rec = None
    phrase_list = None
    sample_rate = args.sample_rate
    show_words = args.show_words
    max_alternatives = args.max_alternatives

    logging.info('Connection from %s', websocket.remote_address);

    while True:

        message = await websocket.recv()

        # Load configuration if provided
        if isinstance(message, str) and 'config' in message:
            jobj = json.loads(message)['config']
            logging.info("Config %s", jobj)
            if 'phrase_list' in jobj:
                phrase_list = jobj['phrase_list']
            if 'sample_rate' in jobj:
                sample_rate = float(jobj['sample_rate'])
            if 'model' in jobj:
                model = Model(jobj['model'])
                model_changed = True
            if 'words' in jobj:
                show_words = bool(jobj['words'])
            if 'max_alternatives' in jobj:
                max_alternatives = int(jobj['max_alternatives'])
            continue

        # Create the recognizer, word list is temporary disabled since not every model supports it
        if not rec or model_changed:
            model_changed = False
            if phrase_list:
                rec = KaldiRecognizer(model, sample_rate, json.dumps(phrase_list, ensure_ascii=False))
            else:
                rec = KaldiRecognizer(model, sample_rate)
            rec.SetWords(show_words)
            rec.SetMaxAlternatives(max_alternatives)
            if spk_model:
                rec.SetSpkModel(spk_model)

        response, stop = await loop.run_in_executor(pool, process_chunk, rec, message)
        if response is not None:
            await websocket.send(response)
        if stop: break


async def start():

    global model
    global spk_model
    global args
    global pool

    # Enable loging if needed
    #
    # logger = logging.getLogger('websockets')
    # logger.setLevel(logging.DEBUG)
    # logger.addHandler(logging.StreamHandler())    
    logging.basicConfig(
        format='%(asctime)s %(levelname)-8s %(message)s',
        level=logging.DEBUG,
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    args = type('', (), {})()

    args.interface = os.environ.get('VOSK_SERVER_INTERFACE', '0.0.0.0')
    args.port = int(os.environ.get('VOSK_SERVER_PORT', 2700))
    args.model_path = os.environ.get('VOSK_MODEL_PATH', 'model')
    args.spk_model_path = os.environ.get('VOSK_SPK_MODEL_PATH')
    args.sample_rate = float(os.environ.get('VOSK_SAMPLE_RATE', 8000))
    args.max_alternatives = int(os.environ.get('VOSK_ALTERNATIVES', 0))
    args.show_words = bool(os.environ.get('VOSK_SHOW_WORDS', True))

    if len(sys.argv) > 1:
       args.model_path = sys.argv[1]

    # Gpu part, uncomment if vosk-api has gpu support
    #
    # from vosk import GpuInit, GpuInstantiate
    # GpuInit()
    # def thread_init():
    #     GpuInstantiate()
    # pool = concurrent.futures.ThreadPoolExecutor(initializer=thread_init)

    model = Model(args.model_path)
    spk_model = SpkModel(args.spk_model_path) if args.spk_model_path else None

    pool = concurrent.futures.ThreadPoolExecutor((os.cpu_count() or 1))

    async with websockets.serve(recognize, args.interface, args.port):
        await asyncio.Future()


if __name__ == '__main__':
    asyncio.run(start())
