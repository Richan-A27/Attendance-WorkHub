package com.isravel.workhub.employee;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {
    private final EmployeeService service;

    public EmployeeController(EmployeeService service) {
        this.service = service;
    }

    @GetMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> list() {
        List<Employee> all = service.findAll();
        return ResponseEntity.ok(new ApiResponse(true, "Employees retrieved", all));
    }

    @GetMapping("/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> get(@PathVariable Long id) {
        return ResponseEntity.ok(new ApiResponse(true, "Employee retrieved", service.findById(id)));
    }

    @PostMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> create(@Valid @RequestBody Employee req) {
        return ResponseEntity.ok(new ApiResponse(true, "Employee created", service.create(req)));
    }

    @PutMapping("/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> update(@PathVariable Long id, @Valid @RequestBody Employee req) {
        return ResponseEntity.ok(new ApiResponse(true, "Employee updated", service.update(id, req)));
    }

    @DeleteMapping("/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.ok(new ApiResponse(true, "Employee deleted", null));
    }

    @PatchMapping("/{id}/hourly-rate")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> patchRate(@PathVariable Long id, @RequestBody BigDecimal rate) {
        return ResponseEntity.ok(new ApiResponse(true, "Hourly rate updated", service.patchHourlyRate(id, rate)));
    }

    @PatchMapping("/{id}/status")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> patchStatus(@PathVariable Long id, @RequestBody Boolean active) {
        return ResponseEntity.ok(new ApiResponse(true, "Status updated", service.patchStatus(id, active)));
    }

    record ApiResponse(boolean success, String message, Object data) {}
}
