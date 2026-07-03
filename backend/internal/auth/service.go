package auth

import (
	"context"
	"errors"
	"time"
	"com.isravel.workhub/internal/config"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

// Service defines authentication and token management operations.
type Service interface {
	Register(ctx context.Context, username, password, role string) error
	Login(ctx context.Context, username, password string) (string, error)
	GenerateToken(username, role string) (string, error)
	ParseToken(tokenStr string) (*jwt.MapClaims, error)
}

type service struct {
	repo Repository
	cfg  *config.Config
}

// NewService creates a new Service instance.
func NewService(repo Repository, cfg *config.Config) Service {
	return &service{repo: repo, cfg: cfg}
}

func (s *service) Register(ctx context.Context, username, password, role string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	if role == "" {
		role = "ADMIN"
	}

	u := &User{
		Username:     username,
		PasswordHash: string(hashedPassword),
		Role:         role,
	}

	return s.repo.Save(ctx, u)
}

func (s *service) Login(ctx context.Context, username, password string) (string, error) {
	u, err := s.repo.FindByUsername(ctx, username)
	if err != nil {
		return "", errors.New("invalid credentials")
	}

	err = bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
	if err != nil {
		return "", errors.New("invalid credentials")
	}

	return s.GenerateToken(u.Username, u.Role)
}

func (s *service) GenerateToken(username, role string) (string, error) {
	claims := jwt.MapClaims{
		"sub":  username,
		"role": role,
		"iat":  time.Now().Unix(),
		"exp":  time.Now().Add(time.Duration(s.cfg.JWTExpirationMs) * time.Millisecond).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.cfg.JWTSecret))
}

func (s *service) ParseToken(tokenStr string) (*jwt.MapClaims, error) {
	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(s.cfg.JWTSecret), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	return &claims, nil
}
