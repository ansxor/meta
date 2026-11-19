from users import get_usr, is_adult


def profile(db, user_id):
    u = get_usr(db, user_id)
    return {"id": user_id, "adult": is_adult(u)}
