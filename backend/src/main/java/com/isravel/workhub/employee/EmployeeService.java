package com.isravel.workhub.employee;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EmployeeService {
    private final EmployeeRepository repo;

    public EmployeeService(EmployeeRepository repo) {
        this.repo = repo;
    }

    public List<Employee> findAll() {
        return repo.findAll();
    }

    public Employee findById(Long id) {
        return repo.findById(id).orElseThrow(() -> new RuntimeException("Employee not found"));
    }

    public Employee create(Employee e) {
        return repo.save(e);
    }

    public Employee update(Long id, Employee updated) {
        Employee existing = findById(id);
        existing.setName(updated.getName());
        existing.setHourlyRate(updated.getHourlyRate());
        existing.setActive(updated.getActive());
        return repo.save(existing);
    }

    public void delete(Long id) {
        repo.deleteById(id);
    }

    public Employee patchHourlyRate(Long id, java.math.BigDecimal rate) {
        Employee e = findById(id);
        e.setHourlyRate(rate);
        return repo.save(e);
    }

    public Employee patchStatus(Long id, Boolean active) {
        Employee e = findById(id);
        e.setActive(active);
        return repo.save(e);
    }

    public long countActive() {
        return repo.countByActiveTrue();
    }
}
