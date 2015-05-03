
// We need all the log functions visible so we set this to DEBUG
#ifdef XPL_COMPILE_TIME_LOG_LEVEL
#undef XPL_COMPILE_TIME_LOG_LEVEL
#define XPL_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG
#endif

#define XPL_COMPILE_TIME_LOG_LEVEL ASL_LEVEL_DEBUG

#import "XPLLogging.h"

static void AddStderrOnce()
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		asl_add_log_file(NULL, STDERR_FILENO);
	});
}

#define __XPL_MAKE_LOG_FUNCTION(LEVEL, NAME) \
void NAME (NSString *format, ...) \
{ \
	AddStderrOnce(); \
	va_list args; \
	va_start(args, format); \
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args]; \
	asl_log(NULL, NULL, (LEVEL), "%s", [message UTF8String]); \
	va_end(args); \
}

__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_EMERG, XPLLogEmergency)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_ALERT, XPLLogAlert)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_CRIT, XPLLogCritical)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_ERR, XPLLogError)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_WARNING, XPLLogWarning)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_NOTICE, XPLLogNotice)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_INFO, XPLLogInfo)
__XPL_MAKE_LOG_FUNCTION(ASL_LEVEL_DEBUG, XPLLogDebug)

#undef __XPL_MAKE_LOG_FUNCTION
