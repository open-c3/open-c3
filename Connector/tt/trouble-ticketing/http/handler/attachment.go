package handler

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"

	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/model"
	"openc3.org/trouble-ticketing/orm"

	"github.com/gin-gonic/gin"
	"github.com/satori/go.uuid"
)

// -- attachment

var (
	maxSize = int64(5 * 1030 * 1030) // 附件最大大小
	maxNum  = int64(5)               // 每个ticket最多附件数
)

type Sizer interface {
	Size() int64
}

// 获取某ticket附件列表
func GetAttachment(c *gin.Context) {
	ticketid := c.Param("ticketid")
	obj := make([]model.TicketAttachment, 0)
	orm.Db.Where("ticket_id = ?", ticketid).Find(&obj)
	c.JSON(http.StatusOK, status_200(obj))
}

// 上传附件, 参数为ticket id
func PostAttachment(c *gin.Context) {

	storeDir := config.Config().Attachment // 附件存储目录 'storeDir/ticketNo/file'

	var ticketA model.TicketAttachment
	c.Request.ParseMultipartForm(maxSize)

	// check request body size
	if c.Request.ContentLength > maxSize {
		c.JSON(http.StatusOK, status_400("File too large."))
		return
	}

	// get 'upload' file
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxSize)
	file, header, err := c.Request.FormFile("upload")
	if err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	filename := header.Filename

	// get file size
	if fileSizer, ok := file.(Sizer); ok {
		ticketA.Size = fileSizer.Size()
	}

	// check ticketid exist
	ticketid := c.Param("ticketid")
	var ticket model.Ticket
	if orm.Db.Where("id = ?", ticketid).First(&ticket).RecordNotFound() {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("Ticket TT%010s not exist.", ticketid)))
		return
	}
	// check ticket's max num of attachments
	var count int64
	orm.Db.Table("openc3_tt_ticket_attachment").Where("ticket_id = ?", ticketid).Count(&count)
	if count >= maxNum {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("Exceeded(%d) the maximum(%d) number of attachments.", count, maxNum)))
		return
	}

	// check if file exist
	var ticketE model.TicketAttachment
	if !orm.Db.Where("ticket_id = ? and name = ?", ticketid, filename).First(&ticketE).RecordNotFound() {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("%s already exist.", filename)))
		return
	}

	// create path
	fileUUID := uuid.NewV4().String()
	path := fmt.Sprintf("%s/%s", storeDir, ticket.No)
	filePath := fmt.Sprintf("%s/%s", path, fileUUID)
	if err := os.MkdirAll(path, os.ModePerm); err != nil {
		c.JSON(http.StatusOK, status_403(err.Error()))
		return
	}

	// write to disk
	out, err := os.Create(filePath)
	defer out.Close()
	if err != nil {
		c.JSON(http.StatusOK, status_403(err.Error()))
		return
	}
	_, err = io.Copy(out, file)
	if err != nil {
		c.JSON(http.StatusOK, status_403(err.Error()))
		return
	}

	// save metadata into db
	ticketA.Name = filename
	ticketA.TicketId = ticket.ID
	ticketA.UUID = fileUUID
	if err = orm.Db.Create(&ticketA).Error; err != nil {
		os.Remove(filePath)
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}

	// sys log
	oauser, _ := c.Get("oauser")
	addCommonSysLog(ticket, oauser.(string), "add", "attachment", filename)

	c.JSON(http.StatusOK, status_200(filename))

}

// 下载附件
func DownloadAttachment(c *gin.Context) {

	storeDir := config.Config().Attachment // 附件存储目录 'storeDir/ticketNo/file'

	ticketid := c.Param("ticketid")
	uuid := c.Param("uuid")
	// check attachemnt exist
	var ticketA model.TicketAttachment
	if orm.Db.Where("ticket_id = ? and uuid = ?", ticketid, uuid).First(&ticketA).RecordNotFound() {
		c.JSON(http.StatusOK, status_404(fmt.Sprintf("File %s not exist.", uuid)))
		return
	}

	// read file from disk
	filePath := fmt.Sprintf("%s/TT%010s/%s", storeDir, ticketid, ticketA.UUID)
	b, err := ioutil.ReadFile(filePath)
	if err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}
	c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", ticketA.Name))
	c.Data(200, "", b)
}

// 删除附件
func DeleteAttachment(c *gin.Context) {

	storeDir := config.Config().Attachment // 附件存储目录 'storeDir/ticketNo/file'

	ticketid := c.Param("ticketid")
	uuid := c.Param("uuid")

	// check ticketid exist
	var ticket model.Ticket
	if orm.Db.Where("id = ?", ticketid).First(&ticket).RecordNotFound() {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("Ticket TT%010s not exist.", ticketid)))
		return
	}

	// check attachemnt exist
	var ticketA model.TicketAttachment
	if orm.Db.Where("ticket_id = ? and uuid = ?", ticketid, uuid).First(&ticketA).RecordNotFound() {
		c.JSON(http.StatusOK, status_400(fmt.Sprintf("File %s not exist.", uuid)))
		return
	}

	// del file from disk
	filePath := fmt.Sprintf("%s/TT%010s/%s", storeDir, ticketid, uuid)
	os.Remove(filePath)

	// del record from db
	if err := orm.Db.Where("ticket_id = ? and uuid = ?", ticketid, uuid).Delete(&ticketA).Error; err != nil {
		c.JSON(http.StatusOK, status_400(err.Error()))
		return
	}

	// sys log
	oauser, _ := c.Get("oauser")
	addCommonSysLog(ticket, oauser.(string), "delete", "attachment", ticketA.Name)

	c.JSON(http.StatusOK, status_200(fmt.Sprintf("delete %s success.", ticketA.Name)))

}
