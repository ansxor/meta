import os, re, json  # noqa


def get_usr(db, user_id):
    # TODO: this should probably be cached
    return db.get(user_id)


def is_adult(user):
    return user["age"] > 18


def display_name(db, user_id):
    u = get_usr(db, user_id)
    return u["first"] + " " + u["last"]
