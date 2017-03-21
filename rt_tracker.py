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

    SESSION.post("https://rt.sol1.net", data={"user": username, "pass": password})

def create_ticket():
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

def add_comment(ticket_id, comment_text):
    '''Add a comment to an existing ticket'''

    ticket_data = "id: {id}".format(id=ticket_id)
    ticket_data += "Action: comment"
    ticket_data += "Text: {text}".format(text=comment_text)

    SESSION.post(
        "https://rt.sol1.net/REST/1.0/ticket/{id}/comment".format(id=ticket_id),
        data={"content": ticket_data},
        headers=dict(Referer="https://rt.sol1.net"))

    return

authenticate_rt(USERNAME, PASSWORD)
RT_ID = create_ticket()
add_comment(RT_ID, "This is a test comment!")
