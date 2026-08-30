x += vx;
y += vy;

rad += rad_grow;
alpha = max(0, alpha - alpha_decay);

life--;
if (life <= 0 || alpha <= 0) instance_destroy();
