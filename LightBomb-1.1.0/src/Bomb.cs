using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;

namespace LightBomb
{
    public partial class Bomb : Form
    {
        private readonly double _fadeValue;
        private readonly bool _disableClose;
        private readonly bool _autoRelight;

        public Bomb(Color lightColor, int fadeInterval, double fadeValue, bool disableClose, bool autoRelight)
        {
            InitializeComponent();

            this.BackColor = lightColor;
            timerFade.Interval = fadeInterval;
            _fadeValue = fadeValue;
            _disableClose = disableClose;
            _autoRelight = autoRelight;

            timerFade.Start();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            e.Cancel = _disableClose;
        }

        private void FadeTick(object sender, EventArgs e)
        {
            this.Opacity -= _fadeValue;
            if (this.Opacity == 0)
            {
                if (_autoRelight) this.Opacity = 1;
                else
                {
                    timerFade.Stop();

                    if (_disableClose) Process.GetCurrentProcess().Kill();
                    else Application.Exit();
                }
            }
        }
    }
}
