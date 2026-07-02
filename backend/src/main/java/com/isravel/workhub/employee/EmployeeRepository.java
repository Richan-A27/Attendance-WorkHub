package com.isravel.workhub.employee;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
    long countByActiveTrue();
    Optional<Employee> findById(Long id);
}
