import logging
from opentelemetry import trace
from opentelemetry.trace import SpanKind
import azure.functions as func
from azure.monitor.opentelemetry import configure_azure_monitor # type: ignore
from utils import transform_context
from clients.azure_blob_storage_client import AzureBlobStorageClient
from helpers.config_helper import ConfigHelper

configure_azure_monitor()

# disable logging from library azure
logging.getLogger("azure").setLevel(logging.ERROR)

app = func.FunctionApp()
logger = logging.getLogger("MyLogger")
tracer = trace.get_tracer("MyLogger")
client = AzureBlobStorageClient(
    config=ConfigHelper(),
    logger=logger,
    tracer=tracer
)

@app.timer_trigger(schedule="0 * * * * *", arg_name="myTimer") 
async def timer_trigger(myTimer: func.TimerRequest, context: func.Context) -> None:
    ctx = transform_context(context)
    with tracer.start_as_current_span("timer_trigger", context=ctx, kind=SpanKind.INTERNAL):
        try:
            content: str = await client.read()
            logger.info(f"Blob content: {content}")
        except Exception as e:
            logger.error(f"Error in timer trigger: {e}")
