package com.isravel.workhub.auth;

import com.isravel.workhub.user.UserEntity;
import com.isravel.workhub.user.UserRepository;
import jakarta.validation.Valid;
import lombok.Data;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthController(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtUtil jwtUtil) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
        if (userRepository.findByUsername(req.getUsername()).isPresent()) {
            return ResponseEntity.badRequest().body(new ApiResponse(false, "Username already exists", null));
        }
        UserEntity u = new UserEntity();
        u.setUsername(req.getUsername());
        u.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        u.setRole(req.getRole() == null ? "ADMIN" : req.getRole());
        u.setCreatedAt(LocalDateTime.now());
        userRepository.save(u);
        return ResponseEntity.ok(new ApiResponse(true, "User registered", null));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req) {
        return userRepository.findByUsername(req.getUsername())
                .map(u -> {
                    if (passwordEncoder.matches(req.getPassword(), u.getPasswordHash())) {
                        String token = jwtUtil.generateToken(u.getUsername(), u.getRole());
                        return ResponseEntity.ok(new ApiResponse(true, "Login successful", new LoginResponse(token)));
                    } else {
                        return ResponseEntity.status(401).body(new ApiResponse(false, "Invalid credentials", null));
                    }
                }).orElseGet(() -> ResponseEntity.status(401).body(new ApiResponse(false, "Invalid credentials", null)));
    }

    @Data
    static class RegisterRequest {
        private String username;
        private String password;
        private String role;
    }

    @Data
    static class LoginRequest {
        private String username;
        private String password;
    }

    @Data
    static class LoginResponse {
        private final String token;
    }

    @Data
    static class ApiResponse {
        private final boolean success;
        private final String message;
        private final Object data;
    }
}
