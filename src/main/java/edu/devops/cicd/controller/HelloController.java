package edu.devops.cicd.controller;

import edu.devops.cicd.metrics.AppMetrics;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class HelloController {

    private final AppMetrics appMetrics;

    @GetMapping("/health")
    public Map<String, String> health() {
        appMetrics.recordRequest();
        return Map.of("status", "UP");
    }

    @GetMapping("/hello/{name}")
    public Map<String, String> hello(@PathVariable("name") String name) {
        appMetrics.recordRequest();
        log.info("Hello endpoint called for name: {}", name);
        return Map.of(
            "message", "Hello your name is " + name
        );
    }

    @PostMapping("/hello/form")
    public Map<String, String> helloForm(@RequestParam("name") String name) {
        appMetrics.recordRequest();
        log.info("Hello form endpoint called for name: {}", name);
        return Map.of(
            "message", "You submitted form with name " + name
        );
    }

    @GetMapping("/error")
    public ResponseEntity<Map<String, String>> simulateError() {
        appMetrics.recordRequest();
        appMetrics.recordError();
        log.error("Simulated application error triggered");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("status", "error", "message", "Simulated error for observability testing"));
    }
}
