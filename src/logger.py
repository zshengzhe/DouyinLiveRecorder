# -*- coding: utf-8 -*-

import os
import sys
from loguru import logger

logger.remove()

custom_format = "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | <level>{level: <8}</level> - <level>{message}</level>"

def _safe_add(*args, **kwargs):
    try:
        return logger.add(*args, **kwargs)
    except OSError as err:
        if getattr(err, "errno", None) == 28 and kwargs.get("enqueue"):
            kwargs = dict(kwargs)
            kwargs["enqueue"] = False
            return logger.add(*args, **kwargs)
        raise

use_enqueue = not (getattr(sys, "frozen", False) and sys.platform == "darwin")

_safe_add(
    sink=sys.stderr,
    format=custom_format,
    level="DEBUG",
    colorize=True,
    enqueue=use_enqueue
)

script_path = os.path.split(os.path.realpath(sys.argv[0]))[0]

_safe_add(
    f"{script_path}/logs/streamget.log",
    level="DEBUG",
    format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | {name}:{function}:{line} - {message}",
    filter=lambda i: i["level"].name != "INFO",
    serialize=False,
    enqueue=use_enqueue,
    retention=1,
    rotation="300 KB",
    encoding='utf-8'
)

_safe_add(
    f"{script_path}/logs/PlayURL.log",
    level="INFO",
    format="{time:YYYY-MM-DD HH:mm:ss.SSS} | {message}",
    filter=lambda i: i["level"].name == "INFO",
    serialize=False,
    enqueue=use_enqueue,
    retention=1,
    rotation="300 KB",
    encoding='utf-8'
)
