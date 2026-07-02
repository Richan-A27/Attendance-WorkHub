package com.isravel.workhub;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class WorkhubApplication {
    public static void main(String[] args) {
        SpringApplication.run(WorkhubApplication.class, args);
    }
}
