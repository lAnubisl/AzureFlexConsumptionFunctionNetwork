from typing import Optional
from contextvars import ContextVar
from opentelemetry.context import Context as OpenTelemetryContext

# Define a ContextVar to hold the ambient context
__ambient_context: ContextVar[Optional[OpenTelemetryContext]] = ContextVar("ambient_context", default=None)

def set_context(ctx: OpenTelemetryContext) -> None:
    """Set the ambient context."""
    __ambient_context.set(ctx)

def get_context() -> Optional[OpenTelemetryContext]:
    """Get the current ambient context."""
    return __ambient_context.get()

def unset_context() -> None:
    """Unset the ambient context."""
    __ambient_context.set(None)
