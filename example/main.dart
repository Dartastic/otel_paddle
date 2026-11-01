// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_paddle/otel_paddle.dart';

/// Traces Paddle calls with OpenTelemetry.
///
/// `otel_paddle` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Paddle call in
/// [tracedPaddle]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'paddle-example');

  // Wraps any Paddle v2 API call in a CLIENT span.
  final paddleId = await tracedPaddle<String>(
    resource: 'Order',
    action: 'example',
    transactionId: 'transaction_8f3a2c',
    subscriptionId: 'subscription_8f3a2c',
    customerId: 'customer_8f3a2c',
    environment: 'example',
    invoke: () async {
      // Make the Paddle call here, then report what it returned.
      return 'paddle_8f3a2c';
    },
  );
  OTelLog.info('tracedPaddle subscriptions.create returned $paddleId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutPaddleInstrumentationAsync.
  await runWithoutPaddleInstrumentationAsync(
    () => tracedPaddle<String>(
      resource: 'Order',
      action: 'example',
      transactionId: 'transaction_8f3a2c',
      subscriptionId: 'subscription_8f3a2c',
      customerId: 'customer_8f3a2c',
      environment: 'example',
      invoke: () async {
        return 'paddle_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
