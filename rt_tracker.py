#!/usr/bin/python3
'''Icinga2 plugin to create and track RT tickets when services and hosts go critical'''

import re
import requests
import json

#load auth data from file
RT_AUTH_FILE = open('rt.auth', 'r')
ICINGA_AUTH_FILE = open('icinga.auth', 'r')

USER_REGEX = re.compile(r'(\")(\w+)(\")')
RT_REGEX = re.compile(r'(# Ticket )(\w+)( created)')

userline = RT_AUTH_FILE.readline()
passline = RT_AUTH_FILE.readline()

RT_DEETS = {}
RT_DEETS['user'] = USER_REGEX.search(userline).group(2)
RT_DEETS['pass'] = USER_REGEX.search(passline).group(2)

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

def get_comments_icinga(username, password, hostname):
    '''Get all icinga comments associated with a hostname'''

    #probs move filters into request body
    res = SESSION.get(
        "https://subview.hq.sol1.net:5665/v1/objects/comments?filter=host.name==\"{hostname}\"&filter=comment.author==\"notifyrt\"".format(hostname=hostname),
        auth=(username, password),
        verify=False,
        headers=dict(Referer="https://subview.hq.sol1.net:5665"))

    print(res.text)
    return

get_comments_icinga(ICINGA_DEETS['user'], ICINGA_DEETS['pass'], "secret ipmi")

# print("running")

# authenticate_rt(RT_DEETS['user'], RT_DEETS['pass'])
# RT_ID = create_ticket_rt()
# add_comment_rt(RT_ID, "This is a test comment!")

# print("done")