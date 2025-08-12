import logging
from typing import Optional
from opentelemetry.trace import Tracer, SpanKind
from azure.identity.aio import DefaultAzureCredential
from azure.storage.blob.aio import BlobServiceClient, BlobClient, StorageStreamDownloader
from helpers.config_helper import ConfigHelper

class AzureBlobStorageClient:

    def __init__(self, config: ConfigHelper, logger: logging.Logger, tracer: Tracer):
        self.__config: ConfigHelper = config
        self.__logger: logging.Logger = logger
        self.__tracer: Tracer = tracer

    async def read(self) -> Optional[str]:
        """
        Read a blob from Azure Blob Storage.
        """
        try:
            with self.__tracer.start_as_current_span("read_blob", kind=SpanKind.CLIENT):
                async with DefaultAzureCredential() as credential:
                    account_name = self.__config.get_storage_account_name()
                    account_url = f"https://{account_name}.blob.core.windows.net"
                    async with BlobServiceClient(account_url, credential=credential) as blob_service_client:
                        container_name = self.__config.get_storage_container_name()
                        async with blob_service_client.get_container_client(container_name) as container_client:
                            blob_client: BlobClient = container_client.get_blob_client("text.txt")
                            downloader: StorageStreamDownloader[str] = await blob_client.download_blob(max_concurrency=1, encoding='UTF-8')
                            content: str = await downloader.readall()
                            return content
        except Exception as e:
            self.__logger.error(f"Error reading blob: {e}")
            return None
