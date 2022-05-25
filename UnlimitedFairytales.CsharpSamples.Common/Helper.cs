﻿using System;

namespace UnlimitedFairytales.CsharpSamples.Common
{
    public class Helper
    {
        public static void Log(string msg = "")
        {
            var dateTime = DateTime.Now.ToString("HH:mm:ss.fff");
            var threadId = "threadId=" + System.Threading.Thread.CurrentThread.ManagedThreadId;
            System.Diagnostics.Trace.WriteLine($"{dateTime} {threadId} {msg}");
        }
    }
}
