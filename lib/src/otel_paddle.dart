// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_paddle_suppression.dart';

const _tracerName = 'dartastic_otel_libs_paddle';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps any Paddle v2 API call in a CLIENT span. The verb in
/// `resource.action` form (e.g. `subscriptions.create`,
/// `transactions.preview`) feeds the span name and
/// `paddle.operation`.
Future<T> tracedPaddle<T>({
  required String resource,
  required String action,
  required Future<T> Function() invoke,
  String? transactionId,
  String? subscriptionId,
  String? customerId,
  String? environment,
}) async {
  if (paddleInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'paddle.resource': resource,
    'paddle.action': action,
    'paddle.operation': '$resource.$action',
  };
  if (transactionId != null) m['paddle.transaction.id'] = transactionId;
  if (subscriptionId != null) m['paddle.subscription.id'] = subscriptionId;
  if (customerId != null) m['paddle.customer.id'] = customerId;
  if (environment != null) m['paddle.environment'] = environment;

  final span = _tracer().startSpan(
    'paddle $resource.$action',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
