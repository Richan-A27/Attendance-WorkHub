package auth

import (
	"net/http"
	"github.com/gin-gonic/gin"
)

// Handler processes incoming registration and login HTTP requests.
type Handler struct {
	svc Service
}

// NewHandler creates a new Handler instance.
func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// Register processes user registration requests.
func (h *Handler) Register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid request payload",
			Data:    nil,
		})
		return
	}

	err := h.svc.Register(c.Request.Context(), req.Username, req.Password, req.Role)
	if err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: err.Error(),
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, ApiResponse{
		Success: true,
		Message: "User registered successfully",
		Data:    nil,
	})
}

// Login processes authentication requests and issues access tokens.
func (h *Handler) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, ApiResponse{
			Success: false,
			Message: "Invalid request payload",
			Data:    nil,
		})
		return
	}

	token, err := h.svc.Login(c.Request.Context(), req.Username, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, ApiResponse{
			Success: false,
			Message: "Invalid credentials",
			Data:    nil,
		})
		return
	}

	c.JSON(http.StatusOK, ApiResponse{
		Success: true,
		Message: "Login successful",
		Data:    LoginResponse{Token: token},
	})
}
