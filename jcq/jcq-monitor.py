#!/home/lizhijian/opt/python3.7/bin/python3

import base64
import collections
import hashlib
import hmac
import json
import random
import requests
from datetime import datetime

def md5(content):
    b = bytes(content, 'utf-8')
    h = hashlib.new('md5')
    h.update(b)
    return h.hexdigest()

def message2str(message):
    m = dict(message)  # deep copy
    m.update(m.get('properties', {}))
    m.pop('properties')
    od = collections.OrderedDict(sorted(m.items()))
    ms = '&'.join([k + '=' + str(v) for k, v in od.items()])
    return md5(ms)

def get_sign_source(headers, params):
    d = {
        'accessKey': headers['accessKey'],
        'dateTime': headers['dateTime'],
    }
    d.update(params)
    if type(d.get('messages')) == list:
        d['messages'] = ','.join([message2str(m) for m in d['messages']])
    od = collections.OrderedDict(sorted(d.items()))
    return '&'.join([k + '=' + str(v) for k, v in od.items()])

def get_signature(source, key):
    key = key.encode('utf-8')
    source = source.encode('utf-8')
    digester = hmac.new(key, source, hashlib.sha1)
    signature = base64.standard_b64encode(digester.digest())
    return signature.decode('utf-8').strip()

def send_message(access_key, secret_key, topic, type_, messages):
    url = 'http://jcq-shared-005-httpsrv-nlb-FI.jvessel-open-sh.jdcloud.com:8080/v1/messages'
    headers = {
        "Content-Type": "application/json",
        "accessKey": access_key,
        "dateTime": datetime.utcnow().isoformat(timespec='seconds') + "Z",
    }
    body = {
        "topic": topic,
        "type": type_,
        "messages": messages,
    }
    sign_source = get_sign_source(headers, body)
    signature = get_signature(sign_source, secret_key)
    headers["signature"] = signature
    resp = requests.post(url, headers=headers, data=json.dumps(body))
    return resp.text

def consume_message(access_key, secret_key, topic, consumerGroupId, size):
    url = 'http://jcq-shared-005-httpsrv-nlb-FI.jvessel-open-sh.jdcloud.com:8080/v1/messages'
    headers = {
        "Content-Type": "application/json",
        "accessKey": access_key,
        "dateTime": datetime.utcnow().isoformat(timespec='seconds') + "Z",
    }
    params = {
        "topic": topic,
        "consumerGroupId": consumerGroupId,
        "size": size
    }
    sign_source = get_sign_source(headers, params)
    signature = get_signature(sign_source, secret_key)
    headers["signature"] = signature
    resp = requests.get(url, headers=headers, params=params)
    return resp.text


def mysend():
    access_key = "28D2D6E3A9E83013676002E980BA17DF"
    secret_key = "F9683ABF2AC11DC82418ECE565EF5C30"
    topic = "monitor_east"
    type_ = "NORMAL"
    messages = [ ]
    for i in range(10):
        messages.append({
            'body': 'message-%d' % i,
            'delaySeconds': random.randint(0, 10),
            'tag': 'tag-%d' % i,
            'properties': {str(random.randint(0, 100)): 'test'}
        })
    resp = send_message(access_key, secret_key, topic, type_, messages)
    res_dict = json.loads(resp)
    res_dict["result"]   
    return len(res_dict["result"]["messageIds"])

def myconsumer():
    access_key = "28D2D6E3A9E83013676002E980BA17DF"
    secret_key = "F9683ABF2AC11DC82418ECE565EF5C30"
    topic = "monitor_east"
    consumerGroupId = "chaos_jcq_consumer"
    size = 3
    resp = consume_message(access_key, secret_key, topic, consumerGroupId, size)
    return resp
 

if __name__ == '__main__':
    status = mysend()
    print (status)
    myconsumer()
