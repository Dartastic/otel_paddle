// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_paddle/otel_paddle.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_paddle-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('transactions.preview records CLIENT span', () async {
    await tracedPaddle<String>(
      resource: 'transactions',
      action: 'preview',
      customerId: 'cus_1',
      environment: 'sandbox',
      invoke: () async => 'preview',
    );
    final a = attrsOf(spans.findSpanByName('paddle transactions.preview')!);
    expect(a['paddle.resource'], 'transactions');
    expect(a['paddle.action'], 'preview');
    expect(a['paddle.operation'], 'transactions.preview');
    expect(a['paddle.customer.id'], 'cus_1');
    expect(a['paddle.environment'], 'sandbox');
  });

  test('suppression skips spans', () async {
    await runWithoutPaddleInstrumentationAsync(() async {
      await tracedPaddle<String>(
        resource: 'transactions',
        action: 'preview',
        invoke: () async => 'p',
      );
    });
    expect(spans.findSpansStartingWith('paddle '), isEmpty);
  });
}
