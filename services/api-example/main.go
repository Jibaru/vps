package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"
)

var db *sql.DB

type Response struct {
	Message string `json:"message"`
}

type HealthResponse struct {
	Status   string `json:"status"`
	Database string `json:"database"`
}

func hello(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(Response{
		Message: "Hello from VPS Template 🚀",
	})
}

func health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	dbStatus := "connected"
	if err := db.Ping(); err != nil {
		dbStatus = "disconnected"
		log.Printf("Database ping failed: %v", err)
	}

	json.NewEncoder(w).Encode(HealthResponse{
		Status:   "ok",
		Database: dbStatus,
	})
}

func initDB() {
	var err error
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Println("DATABASE_URL not set, skipping database connection")
		return
	}

	db, err = sql.Open("postgres", databaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	if err = db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	log.Println("Database connected successfully")
}

func main() {
	initDB()
	defer func() {
		if db != nil {
			db.Close()
		}
	}()

	http.HandleFunc("/hello", hello)
	http.HandleFunc("/health", health)

	log.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
