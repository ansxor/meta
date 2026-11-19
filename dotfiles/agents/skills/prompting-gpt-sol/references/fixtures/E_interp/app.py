import logging

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger("app")


def handle(req):
    log.debug("got request %s", req)
    log.info("handling %s", req.get("path"))
    result = {"ok": True, "path": req.get("path")}
    log.debug("result %s", result)
    return result


if __name__ == "__main__":
    for p in ["/a", "/b", "/c"]:
        handle({"path": p})
