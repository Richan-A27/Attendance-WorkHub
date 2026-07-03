package com.isravel.workhub.settings;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "company_profiles")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CompanyProfile {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_name", nullable = false)
    private String companyName;

    @Column(name = "address")
    private String address;

    @Column(name = "contact_email")
    private String contactEmail;

    @Column(name = "contact_phone")
    private String contactPhone;

    @Column(name = "tax_id")
    private String taxId;

    @Column(name = "day_boundary")
    private java.time.LocalTime dayBoundary = java.time.LocalTime.of(6, 0);
}

