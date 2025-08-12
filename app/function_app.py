import logging
from opentelemetry import trace
import azure.functions as func
from azure.monitor.opentelemetry import configure_azure_monitor # type: ignore
from ambient_context_manager import set_context, unset_context
from utils import transform_context
from clients.azure_blob_storage_client import AzureBlobStorageClient
from helpers.config_helper import ConfigHelper

configure_azure_monitor()

app = func.FunctionApp()

@app.timer_trigger(schedule="0 * * * * *", arg_name="myTimer") 
async def timer_trigger(myTimer: func.TimerRequest, context: func.Context) -> None:
    set_context(transform_context(context))
    try:
        log = logging.getLogger("MyLogger")
        client = AzureBlobStorageClient(
            config=ConfigHelper(),
            logger=log,
            tracer=trace.get_tracer("MyLogger")
        )

        content: str = await client.read()
        log.info(f"Blob content: {content}")
    finally:
        unset_context()
