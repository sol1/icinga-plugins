#!/usr/bin/python3
'''Icinga2 plugin to create and track RT tickets when services and hosts go critical'''

import requests
import re

#load auth data from file
FILE = open('rt.auth', 'r')

USER_REGEX = re.compile(r'(\")(\w+)(\")')
RT_REGEX = re.compile(r'(# Ticket )(\w+)( created)')

userline = FILE.readline()
passline = FILE.readline()

USERNAME = USER_REGEX.search(userline).group(2)
PASSWORD = USER_REGEX.search(passline).group(2)

SESSION = requests.session()

def authenticate_rt(username, password):
    '''Authenticates with the RT server for all subsequent requests'''
    res = SESSION.post("https://rt.sol1.net", data={"user": username, "pass": password})
    # print(res.text)

def create_ticket():
    '''Creates a ticket in RT and returns the ticket ID'''
    ticket_data = '''id: ticket/new
Queue: {queue}
Requestor: matt.streatfield@sol1.com.au
Subject: TEST TICKET - Matt testing RT integration
Text: This is a test ticket'''.format(queue="icinga")

    res = SESSION.post(
        "https://rt.sol1.net/REST/1.0/ticket/new",
        data={"content": ticket_data},
        headers=dict(Referer="https://rt.sol1.net"))

    ID = RT_REGEX.search(res.text).group(2)

    return ID

def add_comment(ticket_id, comment_text):
    '''Add a comment to an existing ticket'''
    ticket_data = '''id: {id}
Action: comment
Text: {text}'''.format(id=ticket_id, text=comment_text)

    res = SESSION.post(
        "https://rt.sol1.net/REST/1.0/ticket/{id}/comment".format(id=ticket_id),
        data={"content": ticket_data},
        headers=dict(Referer="https://rt.sol1.net"))

    print(res.text)
    return

authenticate_rt(USERNAME, PASSWORD)
RT_ID = create_ticket()
add_comment(RT_ID, "This is a test comment!")
