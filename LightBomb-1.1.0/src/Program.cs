using System;
using System.Drawing;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;

namespace LightBomb
{
    internal static class Program
    {
        /// <summary>
        /// 应用程序的主入口点。
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            Color lightColor = Color.White;
            int fadeInterval = 20;
            double fadeValue = 0.1;
            bool disableClose = false;
            bool autoRelight = false;

            if (args.Any(s => s == "-h" || s == "--help"))
            {
                MessageBox.Show($"""
                        LightBomb v{Assembly.GetExecutingAssembly()
                                            .GetCustomAttribute<AssemblyFileVersionAttribute>().Version}
                        © 2026 ByteBesage / 可贤

                        如参数中不包含帮助参数，
                        第一个参数为闪烁颜色，六位十六进制值字串。
                        第二个参数为每次淡出的间隔，表示毫秒，整数。
                        第三个参数为每次淡出的量，0 至 1，双精度浮点。
                        第四个参数为是否禁用关闭，开启表示无法正常关闭，布尔填整数，非零值真，谨慎使用。
                        第五个参数为每次闪烁完毕后是否自动重启，布尔填整数，非零值真，谨慎使用。

                        默认值分别为 ffffff，20，0.1，0，0。
                        当输入无效或未指定时，则使用默认值。可以用无效值跳过不想写的参数。

                        -h | --help
                        显示这个帮助信息。

                        """, "LightBomb");
                Environment.Exit(0);
            }

            try
            {
                if (args[0].Length == 6)
                {
                    UInt16 r = Convert.ToUInt16(args[0].Substring(0, 2), 16);
                    UInt16 g = Convert.ToUInt16(args[0].Substring(2, 2), 16);
                    UInt16 b = Convert.ToUInt16(args[0].Substring(4, 2), 16);

                    lightColor = Color.FromArgb(0xFF, r, g, b);
                }

                if (int.TryParse(args[1], out int a1))
                {
                    fadeInterval = a1;
                }

                if (double.TryParse(args[2], out double a2))
                {
                    fadeValue = a2;
                }

                if (int.TryParse(args[3], out int a3))
                {
                    disableClose = a3 != 0;
                }

                if (int.TryParse(args[4], out int a4))
                {
                    autoRelight = a4 != 0;
                }
            }
            catch (Exception)
            {
                ;
            }

            Application.Run(new Bomb(lightColor, fadeInterval, fadeValue, disableClose, autoRelight));
        }
    }
}
