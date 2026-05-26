#!/usr/bin/env bash

delivery_pipeline_redact_text() {
  perl -pe '
    s#(https?://)[^/\s:@]+:[^/\s@]+@#${1}[REDACTED]@#g;
    s/(Authorization:\s*)[^\r\n]+/${1}[REDACTED]/ig;
    s/(Bearer\s+)[A-Za-z0-9._~+\/=\-]+/${1}[REDACTED]/g;
    s/("(?:input|wa_id)"\s*:\s*")[^"]+/${1}[REDACTED]/g;
    s/("id"\s*:\s*")wamid\.[^"]+/${1}[REDACTED]/g;
    s/\b(gh[pousr]_[A-Za-z0-9_]{20,})\b/[REDACTED]/g;
    s/\b(xox[baprs]-[A-Za-z0-9-]{20,})\b/[REDACTED]/g;
    s/\b(sk-[A-Za-z0-9]{20,})\b/[REDACTED]/g;
    s/\b(AKIA[0-9A-Z]{16})\b/[REDACTED]/g;
    s/((?:api[_-]?key|access[_-]?token|refresh[_-]?token|token|password|secret)=)[^\s&]+/${1}[REDACTED]/ig;
    s/(?<![\w:-])\+?[1-9][0-9\s().-]{8,}[0-9](?![\w:-])/[PHONE]/g;
  '
}