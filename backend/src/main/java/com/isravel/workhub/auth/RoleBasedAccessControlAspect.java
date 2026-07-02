package com.isravel.workhub.auth;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.Collection;

@Aspect
@Component
public class RoleBasedAccessControlAspect {

    @Around("@annotation(requireRole)")
    public Object checkRole(ProceedingJoinPoint joinPoint, RequireRole requireRole) throws Throwable {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new RuntimeException("Not authenticated");
        }

        Collection<? extends GrantedAuthority> authorities = authentication.getAuthorities();
        String[] requiredRoles = requireRole.value();

        boolean hasRequiredRole = authorities.stream().anyMatch(auth -> {
            String grantedRole = auth.getAuthority().replace("ROLE_", "").toUpperCase();
            return Arrays.stream(requiredRoles).anyMatch(required -> required.equalsIgnoreCase(grantedRole));
        });

        if (!hasRequiredRole) {
            throw new RuntimeException("Access denied: insufficient role");
        }

        return joinPoint.proceed();
    }
}
