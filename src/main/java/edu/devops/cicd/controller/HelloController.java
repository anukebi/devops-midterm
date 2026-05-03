package edu.devops.cicd.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class HelloController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "UP");
    }

    @GetMapping("/hello/{name}")
    public Map<String, String> hello(@PathVariable("name") String name) {
        return Map.of(
            "message", "Hello your name is " + name
        );
    }

    @PostMapping("/hello/form")
    public Map<String, String> helloForm(@RequestParam("name") String name) {
        return Map.of(
            "message", "You submitted form with name " + name
        );
    }
}

