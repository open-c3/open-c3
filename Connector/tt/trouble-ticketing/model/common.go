package model

import (
	"time"
)

type CommonReplyLog struct {
	ID        int64     `json:"id"`
	OperUser  string    `json:"oper_user"`
	Content   string    `json:"content"`
	TicketId  int64     `json:"ticket_id"`
	CreatedAt time.Time `json:"created_at"`
}

type CommonWorkLog struct {
	ID        int64     `json:"id"`
	OperUser  string    `json:"oper_user"`
	Content   string    `json:"content"`
	TicketId  int64     `json:"ticket_id"`
	CreatedAt time.Time `json:"created_at"`
}

type CommonSysLog struct {
	ID         int64     `json:"id"`
	OperUser   string    `json:"oper_user"`
	OperType   string    `json:"oper_type"`
	OperColumn string    `json:"oper_column"`
	OperPre    string    `json:"oper_pre"`
	OperAfter  string    `json:"oper_after"`
	Content    string    `json:"content"`
	TicketId   int64     `json:"ticket_id"`
	CreatedAt  time.Time `json:"created_at"`
}

type CommonLang struct {
	ID      int64  `json:"id"`
	Lang    string `json:"lang"`
	Langkey string `json:"langkey"`
	Data    string `json:"data"`
}
