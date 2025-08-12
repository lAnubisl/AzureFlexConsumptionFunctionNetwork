import azure.functions as func
import opentelemetry.context as opentelimetry
from opentelemetry.propagate import extract

def transform_context(func_ctx: func.Context) -> opentelimetry.Context:
    """
    Transform the Azure Function context to the OpenTelemetry context
    Documentation: https://pypi.org/project/azure-monitor-opentelemetry/
    Section: 'Monitoring in Azure Functions'
    """
    return extract({
        "traceparent": func_ctx.trace_context.Traceparent, # type: ignore
        "tracestate": func_ctx.trace_context.Tracestate, # type: ignore
    }) # type: ignore
