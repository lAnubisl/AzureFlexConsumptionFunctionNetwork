import os

class ConfigHelper:

    def get_storage_account_name(self) -> str:
        return os.environ["STORAGE_ACCOUNT_NAME"]

    def get_storage_container_name(self) -> str:
        return os.environ["STORAGE_CONTAINER_NAME"]
