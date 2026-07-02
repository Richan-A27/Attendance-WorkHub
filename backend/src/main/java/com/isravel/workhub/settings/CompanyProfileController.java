package com.isravel.workhub.settings;

import com.isravel.workhub.auth.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/settings/company-profile")
@RequiredArgsConstructor
public class CompanyProfileController {
    
    private final CompanyProfileRepository repository;

    @GetMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<CompanyProfile> getCompanyProfile() {
        return repository.findAll().stream().findFirst()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.ok(new CompanyProfile()));
    }

    @PostMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<CompanyProfile> saveCompanyProfile(@RequestBody CompanyProfile profile) {
        // Since it's a single profile, we can clear existing and save new, or just find first and update.
        CompanyProfile existing = repository.findAll().stream().findFirst().orElse(new CompanyProfile());
        
        existing.setCompanyName(profile.getCompanyName());
        existing.setAddress(profile.getAddress());
        existing.setContactEmail(profile.getContactEmail());
        existing.setContactPhone(profile.getContactPhone());
        existing.setTaxId(profile.getTaxId());
        
        CompanyProfile saved = repository.save(existing);
        return ResponseEntity.ok(saved);
    }
}
