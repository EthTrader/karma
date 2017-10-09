import psycopg2
import praw, prawcore
import json
from datetime import datetime

reddit = praw.Reddit()

users = ["MrKup", "jonesyjonesy", "doppio", "jack", "jtnichol", "Mr_Yukon_C", "HandyNumber", "laughncow", "Dunning_Krugerrands", "nbr1bonehead", "_CapR_", "heliumcraft", "carlslarson"]

for user in users:
    redditor = reddit.redditor(user)
    # print(redditor.created_utc)
    # print(int(redditor.created_utc)*1000)
    # print(datetime.fromtimestamp(int(redditor.created_utc)))
    print(dir(redditor))
