package intelligence

import (
	"context"
	"sort"
	"com.isravel.workhub/internal/employee"
)

// RankingService generates rankings for employees based on metrics.
type RankingService interface {
	RankEmployeesByOverallScore(ctx context.Context, month, year int) ([]EmployeeRanking, error)
	RankEmployeesByAttendance(ctx context.Context, month, year int) ([]EmployeeRanking, error)
	RankEmployeesByPunctuality(ctx context.Context, month, year int) ([]EmployeeRanking, error)
	RankEmployeesByWorkingHours(ctx context.Context, month, year int) ([]EmployeeRanking, error)
	GetTopPerformers(ctx context.Context, month, year int, limit int) ([]EmployeeRanking, error)
}

type rankingService struct {
	scoreEngine  ScoreEngine
	employeeRepo employee.Repository
}

// NewRankingService creates a new RankingService instance.
func NewRankingService(scoreEngine ScoreEngine, employeeRepo employee.Repository) RankingService {
	return &rankingService{
		scoreEngine:  scoreEngine,
		employeeRepo: employeeRepo,
	}
}

func (r *rankingService) RankEmployeesByOverallScore(ctx context.Context, month, year int) ([]EmployeeRanking, error) {
	activeEmployees, err := r.employeeRepo.FindAll(ctx)
	if err != nil {
		return nil, err
	}

	var rankings []EmployeeRanking
	for _, emp := range activeEmployees {
		if !emp.Active {
			continue
		}

		score, err := r.scoreEngine.CalculateEmployeeScore(ctx, emp.ID, month, year)
		if err != nil {
			continue
		}

		rankings = append(rankings, EmployeeRanking{
			EmployeeID:   emp.ID,
			EmployeeName: emp.Name,
			Score:        score,
		})
	}

	sort.Slice(rankings, func(i, j int) bool {
		return rankings[i].Score.OverallScore > rankings[j].Score.OverallScore
	})

	for i := range rankings {
		rankings[i].Rank = i + 1
	}

	return rankings, nil
}

func (r *rankingService) RankEmployeesByAttendance(ctx context.Context, month, year int) ([]EmployeeRanking, error) {
	rankings, err := r.RankEmployeesByOverallScore(ctx, month, year)
	if err != nil {
		return nil, err
	}

	sort.Slice(rankings, func(i, j int) bool {
		return rankings[i].Score.AttendancePercentage > rankings[j].Score.AttendancePercentage
	})

	for i := range rankings {
		rankings[i].Rank = i + 1
	}

	return rankings, nil
}

func (r *rankingService) RankEmployeesByPunctuality(ctx context.Context, month, year int) ([]EmployeeRanking, error) {
	rankings, err := r.RankEmployeesByOverallScore(ctx, month, year)
	if err != nil {
		return nil, err
	}

	sort.Slice(rankings, func(i, j int) bool {
		return rankings[i].Score.PunctualityPercentage > rankings[j].Score.PunctualityPercentage
	})

	for i := range rankings {
		rankings[i].Rank = i + 1
	}

	return rankings, nil
}

func (r *rankingService) RankEmployeesByWorkingHours(ctx context.Context, month, year int) ([]EmployeeRanking, error) {
	rankings, err := r.RankEmployeesByOverallScore(ctx, month, year)
	if err != nil {
		return nil, err
	}

	sort.Slice(rankings, func(i, j int) bool {
		return rankings[i].Score.TotalWorkingHours > rankings[j].Score.TotalWorkingHours
	})

	for i := range rankings {
		rankings[i].Rank = i + 1
	}

	return rankings, nil
}

func (r *rankingService) GetTopPerformers(ctx context.Context, month, year int, limit int) ([]EmployeeRanking, error) {
	rankings, err := r.RankEmployeesByOverallScore(ctx, month, year)
	if err != nil {
		return nil, err
	}

	if len(rankings) > limit {
		return rankings[:limit], nil
	}
	return rankings, nil
}
