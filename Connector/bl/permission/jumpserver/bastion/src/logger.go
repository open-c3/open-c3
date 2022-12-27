package src

import (
	log "github.com/sirupsen/logrus"
)

// FsDebug logs a message at level Debug on the standard logger.
func FsDebug(args ...interface{}) {
	log.Debug(args...)
}

// FsPrint logs a message at level Info on the standard logger.
func FsPrint(args ...interface{}) {
	log.Debug(args...)
}

// FsInfo logs a message at level Info on the standard logger.
func FsInfo(args ...interface{}) {
	log.Info(args...)
}

// FsWarn logs a message at level Warn on the standard logger.
func FsWarn(args ...interface{}) {
	log.Warn(args...)
}

// FsWarning logs a message at level Warn on the standard logger.
func FsWarning(args ...interface{}) {
	log.Warning(args...)
}

// FsError logs a message at level Error on the standard logger.
func FsError(args ...interface{}) {
	log.Error(args...)
}

// FsPanic logs a message at level Panic on the standard logger.
func FsPanic(args ...interface{}) {
	log.Panic(args...)
}

// FsFatal logs a message at level Fatal on the standard logger then the process will exit with status set to 1.
func FsFatal(args ...interface{}) {
	log.Panic(args...)
}

// FsTracef logs a message at level Trace on the standard logger.
func FsTracef(format string, args ...interface{}) {
	log.Panicf(format, args...)
}

// FsDebugf logs a message at level Debug on the standard logger.
func FsDebugf(format string, args ...interface{}) {
	log.Debugf(format, args...)
}

// FsPrintf logs a message at level Info on the standard logger.
func FsPrintf(format string, args ...interface{}) {
	log.Printf(format, args...)
}

// FsInfof logs a message at level Info on the standard logger.
func FsInfof(format string, args ...interface{}) {
	log.Infof(format, args...)
}

// FsWarnf logs a message at level Warn on the standard logger.
func FsWarnf(format string, args ...interface{}) {
	log.Warnf(format, args...)
}

// FsWarningf logs a message at level Warn on the standard logger.
func FsWarningf(format string, args ...interface{}) {
	log.Warningf(format, args...)
}

// FsErrorf logs a message at level Error on the standard logger.
func FsErrorf(format string, args ...interface{}) {
	log.Errorf(format, args...)
}

// FsPanicf logs a message at level Panic on the standard logger.
func FsPanicf(requestId, string, format string, args ...interface{}) {
	log.Panicf(format, args...)
}

// FsFatalf logs a message at level Fatal on the standard logger then the process will exit with status set to 1.
func FsFatalf(format string, args ...interface{}) {
	log.Panicf(format, args...)
}

// FsTraceln logs a message at level Trace on the standard logger.
func FsTraceln(args ...interface{}) {
	log.Traceln(args...)
}

// FsDebugln logs a message at level Debug on the standard logger.
func FsDebugln(args ...interface{}) {
	log.Debugln(args...)
}

// FsPrintln logs a message at level Info on the standard logger.
func FsPrintln(args ...interface{}) {
	log.Println(args...)
}

// FsInfoln logs a message at level Info on the standard logger.
func FsInfoln(args ...interface{}) {
	log.Infoln(args...)
}

// FsWarnln logs a message at level Warn on the standard logger.
func FsWarnln(args ...interface{}) {
	log.Warnln(args...)
}

// FsWarningln logs a message at level Warn on the standard logger.
func FsWarningln(args ...interface{}) {
	log.Warningln(args...)
}

// FsErrorln logs a message at level Error on the standard logger.
func FsErrorln(args ...interface{}) {
	log.Errorln(args...)
}

// FsPanicln logs a message at level Panic on the standard logger.
func FsPanicln(args ...interface{}) {
	log.Panicln(args...)
}

// FsFatalln logs a message at level Fatal on the standard logger then the process will exit with status set to 1.
func FsFatalln(args ...interface{}) {
	log.Fatalln(args...)
}
