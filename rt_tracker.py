#!/usr/bin/python3
'''Icinga2 plugin to create and track RT tickets when services and hosts go critical'''

import re
import json

import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning) #Disable unverified SSL warning

#load auth data from file
RT_AUTH_FILE = open('rt.auth', 'r')
ICINGA_AUTH_FILE = open('icinga.auth', 'r')

USER_REGEX = re.compile(r'(\")(\w+)(\")')
RT_REGEX = re.compile(r'(# Ticket )(\w+)( created)')
TICKETID_REGEX = re.compile(r'(#)([0-9]+)(\])')

RT_DEETS = {}
RT_DEETS['user'] = USER_REGEX.search(RT_AUTH_FILE.readline()).group(2)
RT_DEETS['pass'] = USER_REGEX.search(RT_AUTH_FILE.readline()).group(2)

ICINGA_DEETS = json.loads(ICINGA_AUTH_FILE.readline())

SESSION = requests.session()

def authenticate_rt(username, password):
    '''Authenticates with the RT server for all subsequent requests'''

    SESSION.post("https://rt.sol1.net", data={"user": username, "pass": password})

def create_ticket_rt():
    '''Creates a ticket in RT and returns the ticket ID'''

    ticket_data = "id: ticket/new\n"
    ticket_data += "Queue: {queue}\n".format(queue="icinga")
    ticket_data += "Requestor: matt.streatfield@sol1.com.au\n"
    ticket_data += "Subject: TEST TICKET - Matt testing RT integration\n"
    ticket_data += "Text: This is a test ticket"

    res = SESSION.post(
        "https://rt.sol1.net/REST/1.0/ticket/new",
        data={"content": ticket_data},
        headers=dict(Referer="https://rt.sol1.net"))

    return RT_REGEX.search(res.text).group(2)

def add_comment_rt(ticket_id, comment_text):
    '''Add a comment to an existing RT ticket'''

    ticket_data = "id: {id}\n".format(id=ticket_id)
    ticket_data += "Action: comment\n"
    ticket_data += "Text: {text}".format(text=comment_text)

    SESSION.post(
        "https://rt.sol1.net/REST/1.0/ticket/{id}/comment".format(id=ticket_id),
        data={"content": ticket_data},
        headers=dict(Referer="https://rt.sol1.net"))

    return

def get_comments_icinga(username, password, hostname, servicename):
    '''Get all icinga comments associated with a hostname'''

    filters = 'host.name=="{hostname}"'.format(hostname=hostname)
    filters += '&&service.name=="{servicename}"'.format(servicename=servicename)
    filters += '&&comment.author=="notifyrt"'.format(servicename=servicename)

    body = {'filter': filters}

    #probs move filters into request body
    res = SESSION.get(
        "https://subview.hq.sol1.net:5665/v1/objects/comments",
        auth=(username, password),
        verify=False,
        json=body)

    result = json.loads(res.text)['results']
    if len(result) < 1:
        return None
    else:
        #extract id from comment
        ticket_id = TICKETID_REGEX.search(result[0]['attrs']['text']).group(2)
        return ticket_id

def add_comment_icinga(username, password, hostname, servicename, comment_text):
    '''Create comment on an icinga service or host'''

    filters = 'host.name=="{}"'.format(hostname)
    object_type = 'Host'

    if servicename != "":
        object_type = 'Service'
        filters += '&&service.name=="{}"'.format(servicename)

    body = {
        'filter': filters,
        "type":object_type,
        "author":username,
        "comment":comment_text}

    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8'}

    SESSION.post(
        "https://subview.hq.sol1.net:5665/v1/actions/add-comment",
        auth=(username, password),
        verify=False,
        headers=headers,
        json=body)

    return

authenticate_rt(RT_DEETS['user'], RT_DEETS['pass'])

results = get_comments_icinga(ICINGA_DEETS['user'], ICINGA_DEETS['pass'], "secret ipmi", "")
if results is None:
    print("Create RT ticket and comment ID")
    RT_ID = create_ticket_rt()
    add_comment_icinga(
        ICINGA_DEETS['user'], 
        ICINGA_DEETS['pass'],
        "secret ipmi",
        "",
        '<a href="https://rt.sol1.net/Ticket/Display.html?id={}">[sol1 #{}]</a> - ticket created in RT'.format(str(RT_ID), str(RT_ID)))
else:
    print("Get comment and comment on RT")
    add_comment_rt(results, "ticket existed, commenting")
    print(results)

# add_comment_rt(RT_ID, "This is a test comment!")

# print("done")