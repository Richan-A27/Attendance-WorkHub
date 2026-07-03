package settings

// CompanyProfile represents the company profile configurations.
type CompanyProfile struct {
	ID           uint64 `gorm:"primaryKey;autoIncrement;column:id" json:"id"`
	CompanyName  string `gorm:"not null;column:company_name" json:"companyName"`
	Address      string `gorm:"column:address" json:"address"`
	ContactEmail string `gorm:"column:contact_email" json:"contactEmail"`
	ContactPhone string `gorm:"column:contact_phone" json:"contactPhone"`
	TaxID        string `gorm:"column:tax_id" json:"taxId"`
	DayBoundary  string `gorm:"column:day_boundary;type:time" json:"dayBoundary"`
}

// TableName overrides GORM's default naming behavior to "company_profiles".
func (CompanyProfile) TableName() string {
	return "company_profiles"
}
