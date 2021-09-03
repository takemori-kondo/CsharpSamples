﻿using log4net;
using log4net.Config;
using System;
using System.IO;
using System.Reflection;

namespace UnlimitedFairytales.CsharpSamples.log4net
{
    static class Log4netExtension
    {
        static Log4netExtension()
        {
            entryPointAssembly = Assembly.GetEntryAssembly();
            var loggerRepository = LogManager.GetRepository(entryPointAssembly);
            var fileInfo = new FileInfo("log4net.config.xml");
            XmlConfigurator.Configure(loggerRepository, fileInfo);
        }

        private static Assembly entryPointAssembly;

        public static ILog GetLogger(this object obj, string loggerName)
        {
            return LogManager.GetLogger(entryPointAssembly, loggerName);
        }

        public static ILog GetLogger(this object obj, Type type = null)
        {
            if (type == null)
            {
                type = obj.GetType();
            }
            return LogManager.GetLogger(type);
        }
    }
}
