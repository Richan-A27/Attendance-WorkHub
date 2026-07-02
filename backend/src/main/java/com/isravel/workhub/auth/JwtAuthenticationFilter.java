package com.isravel.workhub.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Base64;
import java.util.List;
import java.util.Map;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            try {
                // Decode JWT claims without signature verification (we trust Supabase's server-side validation)
                // Note: JWT base64url segments lack padding - add it before decoding
                String[] parts = token.split("\\.");
                if (parts.length >= 2) {
                    String segment = parts[1];
                    // Re-add base64 padding
                    int paddingNeeded = (4 - segment.length() % 4) % 4;
                    segment = segment + "=".repeat(paddingNeeded);
                    String payloadJson = new String(Base64.getUrlDecoder().decode(segment));
                    @SuppressWarnings("unchecked")
                    Map<String, Object> claims = objectMapper.readValue(payloadJson, Map.class);

                    String username = (String) claims.get("sub");
                    String role = "ADMIN"; // Default for all authenticated Supabase users

                    // Check app_metadata for role
                    Object appMetadata = claims.get("app_metadata");
                    if (appMetadata instanceof Map<?, ?> appMeta) {
                        Object appRole = appMeta.get("role");
                        if (appRole != null) role = appRole.toString().toUpperCase();
                    }

                    // Check user_metadata for role (overrides app_metadata if present)
                    Object userMetadata = claims.get("user_metadata");
                    if (userMetadata instanceof Map<?, ?> userMeta) {
                        Object userRole = userMeta.get("role");
                        if (userRole != null) role = userRole.toString().toUpperCase();
                    }

                    if (username != null) {
                        UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(
                            username, null,
                            List.of(new SimpleGrantedAuthority("ROLE_" + role))
                        );
                        SecurityContextHolder.getContext().setAuthentication(auth);
                    }
                }
            } catch (Exception e) {
                System.err.println("JWT Parse error: " + e.getMessage());
            }
        }
        filterChain.doFilter(request, response);
    }
}
