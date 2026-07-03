package auth

// RegisterRequest is the JSON payload for registration.
type RegisterRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	Role     string `json:"role"`
}

// LoginRequest is the JSON payload for login.
type LoginRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// LoginResponse contains the generated JWT access token.
type LoginResponse struct {
	Token string `json:"token"`
}

// ApiResponse represents the standard response payload layout.
type ApiResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}
