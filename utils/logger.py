import logging
from pathlib import Path
import sys

log_folder = Path(__file__).resolve().parent.parent / "logs"
log_folder.mkdir(exist_ok=True)

LOG_LEVEL = logging.INFO


def get_logger(name=__name__):

    logger = logging.getLogger(name)

    if not logger.handlers:

        logger.setLevel(logging.INFO)

        msg_format = logging.Formatter(
            "%(asctime)s - %(levelname)s - %(name)s - %(message)s"
        )

        file_handler = logging.FileHandler(log_folder/ "pipeline.log", encoding="utf-8")
        file_handler.setFormatter(msg_format)

        logger.addHandler(file_handler)
        
        # Allow Airflow to handle console logging
        logger.propagate = True

    return logger

