package model

import (
	"time"
)

type Ticket struct {
	ID                  int64     `json:"id"`
	No                  string    `json:"no"`
	SubmitUser          string    `json:"submit_user"`
	ApplyUser           string    `json:"apply_user"`
	Status              string    `json:"status"`
	Impact              int64     `json:"impact"`
	Category            int64     `json:"category"`
	Type                int64     `json:"type"`
	Item                int64     `json:"item"`
	Workgroup           int64     `json:"workgroup"`
	GroupUser           int64     `json:"group_user"`
	Title               string    `json:"title"`
	Content             string    `json:"content"`
	EmailList           string    `json:"email_list"`
	RootCause           string    `json:"root_cause"`
	Solution            string    `json:"solution"`
	ResponseTime        time.Time `json:"response_time"`
	ResponseCost        int64     `json:"response_cost"`
	ResponseTimeoutSent int64     `json:"response_timeout_sent"`
	ResolveTime         time.Time `json:"resolve_time"`
	ResolveCost         int64     `json:"resolve_cost"`
	ResolveTimeoutSent  int64     `json:"resolve_timeout_sent"`
	ClosedTime          time.Time `json:"closed_time"`
	OneTimeResolveRate  int64     `json:"one_time_resolve_rate"`
	CreatedAt           time.Time `json:"created_at"`
}

type TicketAttachment struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	Size      int64     `json:"size"`
	UUID      string    `json:"uuid"`
	TicketId  int64     `json:"ticket_id"`
	CreatedAt time.Time `json:"created_at"`
}
