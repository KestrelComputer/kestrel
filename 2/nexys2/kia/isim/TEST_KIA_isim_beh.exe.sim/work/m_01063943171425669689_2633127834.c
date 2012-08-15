/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x54af6ca1 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "/home/kc5tja/Projects/kestrel/2/nexys2/kia/test-top.v";
static int ng1[] = {0, 0};
static int ng2[] = {1, 0};
static const char *ng3 = "Single cycle response expected.";
static unsigned int ng4[] = {1U, 0U};
static const char *ng5 = "Expected queue to be empty.";
static unsigned int ng6[] = {16U, 0U};
static unsigned int ng7[] = {0U, 0U};
static const char *ng8 = "Expected queue to be neither full nor empty.";
static unsigned int ng9[] = {32U, 0U};
static unsigned int ng10[] = {27U, 0U};
static const char *ng11 = "Head of the queue doesn't have the right data byte.";
static unsigned int ng12[] = {48U, 0U};
static unsigned int ng13[] = {224U, 0U};
static const char *ng14 = "Expected 8'hE0 for first byte.";
static const char *ng15 = "Expected 8'h1B for second byte.";



static void Always_41_0(char *t0)
{
    char t3[8];
    char *t1;
    char *t2;
    char *t4;
    char *t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    unsigned int t11;
    unsigned int t12;
    char *t13;
    char *t14;
    char *t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    unsigned int t23;
    char *t24;

LAB0:    t1 = (t0 + 3800U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(41, ng0);

LAB4:    xsi_set_current_line(42, ng0);
    t2 = (t0 + 3608);
    xsi_process_wait(t2, 50000LL);
    *((char **)t1) = &&LAB5;

LAB1:    return;
LAB5:    xsi_set_current_line(42, ng0);
    t4 = (t0 + 1608);
    t5 = (t4 + 56U);
    t6 = *((char **)t5);
    memset(t3, 0, 8);
    t7 = (t6 + 4);
    t8 = *((unsigned int *)t7);
    t9 = (~(t8));
    t10 = *((unsigned int *)t6);
    t11 = (t10 & t9);
    t12 = (t11 & 1U);
    if (t12 != 0)
        goto LAB9;

LAB7:    if (*((unsigned int *)t7) == 0)
        goto LAB6;

LAB8:    t13 = (t3 + 4);
    *((unsigned int *)t3) = 1;
    *((unsigned int *)t13) = 1;

LAB9:    t14 = (t3 + 4);
    t15 = (t6 + 4);
    t16 = *((unsigned int *)t6);
    t17 = (~(t16));
    *((unsigned int *)t3) = t17;
    *((unsigned int *)t14) = 0;
    if (*((unsigned int *)t15) != 0)
        goto LAB11;

LAB10:    t22 = *((unsigned int *)t3);
    *((unsigned int *)t3) = (t22 & 1U);
    t23 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t23 & 1U);
    t24 = (t0 + 1608);
    xsi_vlogvar_wait_assign_value(t24, t3, 0, 0, 1, 0LL);
    goto LAB2;

LAB6:    *((unsigned int *)t3) = 1;
    goto LAB9;

LAB11:    t18 = *((unsigned int *)t3);
    t19 = *((unsigned int *)t15);
    *((unsigned int *)t3) = (t18 | t19);
    t20 = *((unsigned int *)t14);
    t21 = *((unsigned int *)t15);
    *((unsigned int *)t14) = (t20 | t21);
    goto LAB10;

}

static void Initial_45_1(char *t0)
{
    char t14[8];
    char *t1;
    char *t2;
    char *t3;
    char *t4;
    char *t5;
    unsigned int t6;
    unsigned int t7;
    unsigned int t8;
    unsigned int t9;
    unsigned int t10;
    char *t11;
    char *t12;
    char *t13;
    unsigned int t15;
    unsigned int t16;
    unsigned int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned int t22;
    char *t23;
    unsigned int t24;
    unsigned int t25;
    unsigned int t26;
    unsigned int t27;
    unsigned int t28;
    char *t29;
    char *t30;
    char *t31;

LAB0:    t1 = (t0 + 4048U);
    t2 = *((char **)t1);
    if (t2 == 0)
        goto LAB2;

LAB3:    goto *t2;

LAB2:    xsi_set_current_line(45, ng0);

LAB4:    xsi_set_current_line(46, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(47, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1608);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(48, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(49, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(50, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(51, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(52, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(53, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(54, ng0);

LAB5:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB7;

LAB6:    t11 = (t0 + 4368);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB5;

LAB1:    return;
LAB7:    t13 = (t0 + 4368);
    *((int *)t13) = 0;
    xsi_set_current_line(55, ng0);

LAB8:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB12;

LAB10:    if (*((unsigned int *)t5) == 0)
        goto LAB9;

LAB11:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB12:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB14;

LAB13:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB16;

LAB15:    t29 = (t0 + 4384);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB8;
    goto LAB1;

LAB9:    *((unsigned int *)t14) = 1;
    goto LAB12;

LAB14:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB13;

LAB16:    t31 = (t0 + 4384);
    *((int *)t31) = 0;
    xsi_set_current_line(61, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 16, 0LL);
    xsi_set_current_line(62, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(63, ng0);

LAB17:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB19;

LAB18:    t11 = (t0 + 4400);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB17;
    goto LAB1;

LAB19:    t13 = (t0 + 4400);
    *((int *)t13) = 0;
    xsi_set_current_line(63, ng0);

LAB20:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB24;

LAB22:    if (*((unsigned int *)t5) == 0)
        goto LAB21;

LAB23:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB24:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB26;

LAB25:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB28;

LAB27:    t29 = (t0 + 4416);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB20;
    goto LAB1;

LAB21:    *((unsigned int *)t14) = 1;
    goto LAB24;

LAB26:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB25;

LAB28:    t31 = (t0 + 4416);
    *((int *)t31) = 0;
    xsi_set_current_line(64, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(65, ng0);

LAB29:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB31;

LAB30:    t11 = (t0 + 4432);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB29;
    goto LAB1;

LAB31:    t13 = (t0 + 4432);
    *((int *)t13) = 0;
    xsi_set_current_line(65, ng0);

LAB32:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB36;

LAB34:    if (*((unsigned int *)t5) == 0)
        goto LAB33;

LAB35:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB36:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB38;

LAB37:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB40;

LAB39:    t29 = (t0 + 4448);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB32;
    goto LAB1;

LAB33:    *((unsigned int *)t14) = 1;
    goto LAB36;

LAB38:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB37;

LAB40:    t31 = (t0 + 4448);
    *((int *)t31) = 0;
    xsi_set_current_line(66, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(67, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(68, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(69, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(70, ng0);

LAB41:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB43;

LAB42:    t11 = (t0 + 4464);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB41;
    goto LAB1;

LAB43:    t13 = (t0 + 4464);
    *((int *)t13) = 0;
    xsi_set_current_line(70, ng0);

LAB44:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB48;

LAB46:    if (*((unsigned int *)t5) == 0)
        goto LAB45;

LAB47:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB48:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB50;

LAB49:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB52;

LAB51:    t29 = (t0 + 4480);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB44;
    goto LAB1;

LAB45:    *((unsigned int *)t14) = 1;
    goto LAB48;

LAB50:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB49;

LAB52:    t31 = (t0 + 4480);
    *((int *)t31) = 0;
    xsi_set_current_line(71, ng0);
    t2 = (t0 + 1048U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng2)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB54;

LAB53:    if (t19 != 0)
        goto LAB55;

LAB56:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB57;

LAB58:
LAB59:    xsi_set_current_line(74, ng0);
    t2 = (t0 + 1208U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng4)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB62;

LAB61:    if (t19 != 0)
        goto LAB63;

LAB64:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB65;

LAB66:
LAB67:    xsi_set_current_line(82, ng0);
    t2 = ((char*)((ng6)));
    t3 = (t0 + 2888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 16, 0LL);
    xsi_set_current_line(83, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(84, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(85, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(86, ng0);

LAB69:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB71;

LAB70:    t11 = (t0 + 4496);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB69;
    goto LAB1;

LAB54:    *((unsigned int *)t14) = 1;
    goto LAB56;

LAB55:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB56;

LAB57:    xsi_set_current_line(71, ng0);

LAB60:    xsi_set_current_line(72, ng0);
    xsi_vlogfile_write(1, 0, 0, ng3, 1, t0);
    xsi_set_current_line(72, ng0);
    xsi_vlog_stop(1);
    goto LAB59;

LAB62:    *((unsigned int *)t14) = 1;
    goto LAB64;

LAB63:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB64;

LAB65:    xsi_set_current_line(74, ng0);

LAB68:    xsi_set_current_line(75, ng0);
    xsi_vlogfile_write(1, 0, 0, ng5, 1, t0);
    xsi_set_current_line(75, ng0);
    xsi_vlog_stop(1);
    goto LAB67;

LAB71:    t13 = (t0 + 4496);
    *((int *)t13) = 0;
    xsi_set_current_line(86, ng0);

LAB72:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB76;

LAB74:    if (*((unsigned int *)t5) == 0)
        goto LAB73;

LAB75:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB76:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB78;

LAB77:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB80;

LAB79:    t29 = (t0 + 4512);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB72;
    goto LAB1;

LAB73:    *((unsigned int *)t14) = 1;
    goto LAB76;

LAB78:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB77;

LAB80:    t31 = (t0 + 4512);
    *((int *)t31) = 0;
    xsi_set_current_line(87, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(88, ng0);

LAB81:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB83;

LAB82:    t11 = (t0 + 4528);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB81;
    goto LAB1;

LAB83:    t13 = (t0 + 4528);
    *((int *)t13) = 0;
    xsi_set_current_line(88, ng0);

LAB84:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB88;

LAB86:    if (*((unsigned int *)t5) == 0)
        goto LAB85;

LAB87:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB88:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB90;

LAB89:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB92;

LAB91:    t29 = (t0 + 4544);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB84;
    goto LAB1;

LAB85:    *((unsigned int *)t14) = 1;
    goto LAB88;

LAB90:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB89;

LAB92:    t31 = (t0 + 4544);
    *((int *)t31) = 0;
    xsi_set_current_line(89, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(89, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB93;
    goto LAB1;

LAB93:    xsi_set_current_line(89, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(89, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB94;
    goto LAB1;

LAB94:    xsi_set_current_line(89, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(90, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(90, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB95;
    goto LAB1;

LAB95:    xsi_set_current_line(90, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(90, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB96;
    goto LAB1;

LAB96:    xsi_set_current_line(90, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(91, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(91, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB97;
    goto LAB1;

LAB97:    xsi_set_current_line(91, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(91, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB98;
    goto LAB1;

LAB98:    xsi_set_current_line(91, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(92, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(92, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB99;
    goto LAB1;

LAB99:    xsi_set_current_line(92, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(92, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB100;
    goto LAB1;

LAB100:    xsi_set_current_line(92, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(93, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(93, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB101;
    goto LAB1;

LAB101:    xsi_set_current_line(93, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(93, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB102;
    goto LAB1;

LAB102:    xsi_set_current_line(93, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(94, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(94, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB103;
    goto LAB1;

LAB103:    xsi_set_current_line(94, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(94, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB104;
    goto LAB1;

LAB104:    xsi_set_current_line(94, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(95, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(95, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB105;
    goto LAB1;

LAB105:    xsi_set_current_line(95, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(95, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB106;
    goto LAB1;

LAB106:    xsi_set_current_line(95, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(96, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(96, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB107;
    goto LAB1;

LAB107:    xsi_set_current_line(96, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(96, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB108;
    goto LAB1;

LAB108:    xsi_set_current_line(96, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(97, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(97, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB109;
    goto LAB1;

LAB109:    xsi_set_current_line(97, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(97, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB110;
    goto LAB1;

LAB110:    xsi_set_current_line(97, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(98, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(98, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB111;
    goto LAB1;

LAB111:    xsi_set_current_line(98, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(98, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB112;
    goto LAB1;

LAB112:    xsi_set_current_line(98, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(99, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(99, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB113;
    goto LAB1;

LAB113:    xsi_set_current_line(99, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(99, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB114;
    goto LAB1;

LAB114:    xsi_set_current_line(99, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(100, ng0);

LAB115:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB117;

LAB116:    t11 = (t0 + 4560);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB115;
    goto LAB1;

LAB117:    t13 = (t0 + 4560);
    *((int *)t13) = 0;
    xsi_set_current_line(100, ng0);

LAB118:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB122;

LAB120:    if (*((unsigned int *)t5) == 0)
        goto LAB119;

LAB121:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB122:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB124;

LAB123:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB126;

LAB125:    t29 = (t0 + 4576);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB118;
    goto LAB1;

LAB119:    *((unsigned int *)t14) = 1;
    goto LAB122;

LAB124:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB123;

LAB126:    t31 = (t0 + 4576);
    *((int *)t31) = 0;
    xsi_set_current_line(101, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(102, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(103, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(104, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(105, ng0);

LAB127:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB129;

LAB128:    t11 = (t0 + 4592);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB127;
    goto LAB1;

LAB129:    t13 = (t0 + 4592);
    *((int *)t13) = 0;
    xsi_set_current_line(105, ng0);

LAB130:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB134;

LAB132:    if (*((unsigned int *)t5) == 0)
        goto LAB131;

LAB133:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB134:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB136;

LAB135:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB138;

LAB137:    t29 = (t0 + 4608);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB130;
    goto LAB1;

LAB131:    *((unsigned int *)t14) = 1;
    goto LAB134;

LAB136:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB135;

LAB138:    t31 = (t0 + 4608);
    *((int *)t31) = 0;
    xsi_set_current_line(106, ng0);
    t2 = (t0 + 1048U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng2)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB140;

LAB139:    if (t19 != 0)
        goto LAB141;

LAB142:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB143;

LAB144:
LAB145:    xsi_set_current_line(109, ng0);
    t2 = (t0 + 1208U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng7)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB148;

LAB147:    if (t19 != 0)
        goto LAB149;

LAB150:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB151;

LAB152:
LAB153:    xsi_set_current_line(117, ng0);
    t2 = ((char*)((ng9)));
    t3 = (t0 + 2888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 16, 0LL);
    xsi_set_current_line(118, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(119, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(120, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(121, ng0);

LAB155:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB157;

LAB156:    t11 = (t0 + 4624);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB155;
    goto LAB1;

LAB140:    *((unsigned int *)t14) = 1;
    goto LAB142;

LAB141:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB142;

LAB143:    xsi_set_current_line(106, ng0);

LAB146:    xsi_set_current_line(107, ng0);
    xsi_vlogfile_write(1, 0, 0, ng3, 1, t0);
    xsi_set_current_line(107, ng0);
    xsi_vlog_stop(1);
    goto LAB145;

LAB148:    *((unsigned int *)t14) = 1;
    goto LAB150;

LAB149:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB150;

LAB151:    xsi_set_current_line(109, ng0);

LAB154:    xsi_set_current_line(110, ng0);
    xsi_vlogfile_write(1, 0, 0, ng8, 1, t0);
    xsi_set_current_line(110, ng0);
    xsi_vlog_stop(1);
    goto LAB153;

LAB157:    t13 = (t0 + 4624);
    *((int *)t13) = 0;
    xsi_set_current_line(121, ng0);

LAB158:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB162;

LAB160:    if (*((unsigned int *)t5) == 0)
        goto LAB159;

LAB161:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB162:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB164;

LAB163:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB166;

LAB165:    t29 = (t0 + 4640);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB158;
    goto LAB1;

LAB159:    *((unsigned int *)t14) = 1;
    goto LAB162;

LAB164:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB163;

LAB166:    t31 = (t0 + 4640);
    *((int *)t31) = 0;
    xsi_set_current_line(122, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(123, ng0);

LAB167:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB169;

LAB168:    t11 = (t0 + 4656);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB167;
    goto LAB1;

LAB169:    t13 = (t0 + 4656);
    *((int *)t13) = 0;
    xsi_set_current_line(123, ng0);

LAB170:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB174;

LAB172:    if (*((unsigned int *)t5) == 0)
        goto LAB171;

LAB173:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB174:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB176;

LAB175:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB178;

LAB177:    t29 = (t0 + 4672);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB170;
    goto LAB1;

LAB171:    *((unsigned int *)t14) = 1;
    goto LAB174;

LAB176:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB175;

LAB178:    t31 = (t0 + 4672);
    *((int *)t31) = 0;
    xsi_set_current_line(124, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(124, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB179;
    goto LAB1;

LAB179:    xsi_set_current_line(124, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(124, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB180;
    goto LAB1;

LAB180:    xsi_set_current_line(124, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(125, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(125, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB181;
    goto LAB1;

LAB181:    xsi_set_current_line(125, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(125, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB182;
    goto LAB1;

LAB182:    xsi_set_current_line(125, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(126, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(126, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB183;
    goto LAB1;

LAB183:    xsi_set_current_line(126, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(126, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB184;
    goto LAB1;

LAB184:    xsi_set_current_line(126, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(127, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(127, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB185;
    goto LAB1;

LAB185:    xsi_set_current_line(127, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(127, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB186;
    goto LAB1;

LAB186:    xsi_set_current_line(127, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(128, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(128, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB187;
    goto LAB1;

LAB187:    xsi_set_current_line(128, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(128, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB188;
    goto LAB1;

LAB188:    xsi_set_current_line(128, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(129, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(129, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB189;
    goto LAB1;

LAB189:    xsi_set_current_line(129, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(129, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB190;
    goto LAB1;

LAB190:    xsi_set_current_line(129, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(130, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(130, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB191;
    goto LAB1;

LAB191:    xsi_set_current_line(130, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(130, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB192;
    goto LAB1;

LAB192:    xsi_set_current_line(130, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(131, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(131, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB193;
    goto LAB1;

LAB193:    xsi_set_current_line(131, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(131, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB194;
    goto LAB1;

LAB194:    xsi_set_current_line(131, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(132, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(132, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB195;
    goto LAB1;

LAB195:    xsi_set_current_line(132, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(132, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB196;
    goto LAB1;

LAB196:    xsi_set_current_line(132, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(133, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(133, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB197;
    goto LAB1;

LAB197:    xsi_set_current_line(133, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(133, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB198;
    goto LAB1;

LAB198:    xsi_set_current_line(133, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(134, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(134, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB199;
    goto LAB1;

LAB199:    xsi_set_current_line(134, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(134, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB200;
    goto LAB1;

LAB200:    xsi_set_current_line(134, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(135, ng0);

LAB201:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB203;

LAB202:    t11 = (t0 + 4688);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB201;
    goto LAB1;

LAB203:    t13 = (t0 + 4688);
    *((int *)t13) = 0;
    xsi_set_current_line(135, ng0);

LAB204:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB208;

LAB206:    if (*((unsigned int *)t5) == 0)
        goto LAB205;

LAB207:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB208:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB210;

LAB209:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB212;

LAB211:    t29 = (t0 + 4704);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB204;
    goto LAB1;

LAB205:    *((unsigned int *)t14) = 1;
    goto LAB208;

LAB210:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB209;

LAB212:    t31 = (t0 + 4704);
    *((int *)t31) = 0;
    xsi_set_current_line(136, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(137, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(138, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(139, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(140, ng0);

LAB213:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB215;

LAB214:    t11 = (t0 + 4720);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB213;
    goto LAB1;

LAB215:    t13 = (t0 + 4720);
    *((int *)t13) = 0;
    xsi_set_current_line(140, ng0);

LAB216:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB220;

LAB218:    if (*((unsigned int *)t5) == 0)
        goto LAB217;

LAB219:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB220:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB222;

LAB221:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB224;

LAB223:    t29 = (t0 + 4736);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB216;
    goto LAB1;

LAB217:    *((unsigned int *)t14) = 1;
    goto LAB220;

LAB222:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB221;

LAB224:    t31 = (t0 + 4736);
    *((int *)t31) = 0;
    xsi_set_current_line(141, ng0);
    t2 = (t0 + 1048U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng2)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB226;

LAB225:    if (t19 != 0)
        goto LAB227;

LAB228:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB229;

LAB230:
LAB231:    xsi_set_current_line(144, ng0);
    t2 = (t0 + 1208U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng10)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB234;

LAB233:    if (t19 != 0)
        goto LAB235;

LAB236:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB237;

LAB238:
LAB239:    xsi_set_current_line(152, ng0);
    t2 = ((char*)((ng12)));
    t3 = (t0 + 2888);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 16, 0LL);
    xsi_set_current_line(153, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(154, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(155, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(156, ng0);

LAB241:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB243;

LAB242:    t11 = (t0 + 4752);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB241;
    goto LAB1;

LAB226:    *((unsigned int *)t14) = 1;
    goto LAB228;

LAB227:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB228;

LAB229:    xsi_set_current_line(141, ng0);

LAB232:    xsi_set_current_line(142, ng0);
    xsi_vlogfile_write(1, 0, 0, ng3, 1, t0);
    xsi_set_current_line(142, ng0);
    xsi_vlog_stop(1);
    goto LAB231;

LAB234:    *((unsigned int *)t14) = 1;
    goto LAB236;

LAB235:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB236;

LAB237:    xsi_set_current_line(144, ng0);

LAB240:    xsi_set_current_line(145, ng0);
    xsi_vlogfile_write(1, 0, 0, ng11, 1, t0);
    xsi_set_current_line(145, ng0);
    xsi_vlog_stop(1);
    goto LAB239;

LAB243:    t13 = (t0 + 4752);
    *((int *)t13) = 0;
    xsi_set_current_line(156, ng0);

LAB244:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB248;

LAB246:    if (*((unsigned int *)t5) == 0)
        goto LAB245;

LAB247:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB248:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB250;

LAB249:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB252;

LAB251:    t29 = (t0 + 4768);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB244;
    goto LAB1;

LAB245:    *((unsigned int *)t14) = 1;
    goto LAB248;

LAB250:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB249;

LAB252:    t31 = (t0 + 4768);
    *((int *)t31) = 0;
    xsi_set_current_line(157, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1768);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(158, ng0);

LAB253:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB255;

LAB254:    t11 = (t0 + 4784);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB253;
    goto LAB1;

LAB255:    t13 = (t0 + 4784);
    *((int *)t13) = 0;
    xsi_set_current_line(158, ng0);

LAB256:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB260;

LAB258:    if (*((unsigned int *)t5) == 0)
        goto LAB257;

LAB259:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB260:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB262;

LAB261:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB264;

LAB263:    t29 = (t0 + 4800);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB256;
    goto LAB1;

LAB257:    *((unsigned int *)t14) = 1;
    goto LAB260;

LAB262:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB261;

LAB264:    t31 = (t0 + 4800);
    *((int *)t31) = 0;
    xsi_set_current_line(159, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(159, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB265;
    goto LAB1;

LAB265:    xsi_set_current_line(159, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(159, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB266;
    goto LAB1;

LAB266:    xsi_set_current_line(159, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(160, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(160, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB267;
    goto LAB1;

LAB267:    xsi_set_current_line(160, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(160, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB268;
    goto LAB1;

LAB268:    xsi_set_current_line(160, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(161, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(161, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB269;
    goto LAB1;

LAB269:    xsi_set_current_line(161, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(161, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB270;
    goto LAB1;

LAB270:    xsi_set_current_line(161, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(162, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(162, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB271;
    goto LAB1;

LAB271:    xsi_set_current_line(162, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(162, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB272;
    goto LAB1;

LAB272:    xsi_set_current_line(162, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(163, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(163, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB273;
    goto LAB1;

LAB273:    xsi_set_current_line(163, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(163, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB274;
    goto LAB1;

LAB274:    xsi_set_current_line(163, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(164, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(164, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB275;
    goto LAB1;

LAB275:    xsi_set_current_line(164, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(164, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB276;
    goto LAB1;

LAB276:    xsi_set_current_line(164, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(165, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(165, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB277;
    goto LAB1;

LAB277:    xsi_set_current_line(165, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(165, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB278;
    goto LAB1;

LAB278:    xsi_set_current_line(165, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(166, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(166, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB279;
    goto LAB1;

LAB279:    xsi_set_current_line(166, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(166, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB280;
    goto LAB1;

LAB280:    xsi_set_current_line(166, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(167, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(167, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB281;
    goto LAB1;

LAB281:    xsi_set_current_line(167, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(167, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB282;
    goto LAB1;

LAB282:    xsi_set_current_line(167, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(168, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(168, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB283;
    goto LAB1;

LAB283:    xsi_set_current_line(168, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(168, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB284;
    goto LAB1;

LAB284:    xsi_set_current_line(168, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(169, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(169, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB285;
    goto LAB1;

LAB285:    xsi_set_current_line(169, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(169, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB286;
    goto LAB1;

LAB286:    xsi_set_current_line(169, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(171, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(171, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB287;
    goto LAB1;

LAB287:    xsi_set_current_line(171, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(171, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB288;
    goto LAB1;

LAB288:    xsi_set_current_line(171, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(172, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(172, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB289;
    goto LAB1;

LAB289:    xsi_set_current_line(172, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(172, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB290;
    goto LAB1;

LAB290:    xsi_set_current_line(172, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(173, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(173, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB291;
    goto LAB1;

LAB291:    xsi_set_current_line(173, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(173, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB292;
    goto LAB1;

LAB292:    xsi_set_current_line(173, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(174, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(174, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB293;
    goto LAB1;

LAB293:    xsi_set_current_line(174, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(174, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB294;
    goto LAB1;

LAB294:    xsi_set_current_line(174, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(175, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(175, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB295;
    goto LAB1;

LAB295:    xsi_set_current_line(175, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(175, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB296;
    goto LAB1;

LAB296:    xsi_set_current_line(175, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(176, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(176, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB297;
    goto LAB1;

LAB297:    xsi_set_current_line(176, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(176, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB298;
    goto LAB1;

LAB298:    xsi_set_current_line(176, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(177, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(177, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB299;
    goto LAB1;

LAB299:    xsi_set_current_line(177, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(177, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB300;
    goto LAB1;

LAB300:    xsi_set_current_line(177, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(178, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(178, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB301;
    goto LAB1;

LAB301:    xsi_set_current_line(178, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(178, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB302;
    goto LAB1;

LAB302:    xsi_set_current_line(178, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(179, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(179, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB303;
    goto LAB1;

LAB303:    xsi_set_current_line(179, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(179, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB304;
    goto LAB1;

LAB304:    xsi_set_current_line(179, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(180, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(180, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB305;
    goto LAB1;

LAB305:    xsi_set_current_line(180, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(180, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB306;
    goto LAB1;

LAB306:    xsi_set_current_line(180, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(181, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2728);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(181, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB307;
    goto LAB1;

LAB307:    xsi_set_current_line(181, ng0);
    t3 = ((char*)((ng1)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(181, ng0);
    t2 = (t0 + 3856);
    xsi_process_wait(t2, 32768000LL);
    *((char **)t1) = &&LAB308;
    goto LAB1;

LAB308:    xsi_set_current_line(181, ng0);
    t3 = ((char*)((ng2)));
    t4 = (t0 + 2568);
    xsi_vlogvar_wait_assign_value(t4, t3, 0, 0, 1, 0LL);
    xsi_set_current_line(182, ng0);

LAB309:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB311;

LAB310:    t11 = (t0 + 4816);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB309;
    goto LAB1;

LAB311:    t13 = (t0 + 4816);
    *((int *)t13) = 0;
    xsi_set_current_line(182, ng0);

LAB312:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB316;

LAB314:    if (*((unsigned int *)t5) == 0)
        goto LAB313;

LAB315:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB316:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB318;

LAB317:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB320;

LAB319:    t29 = (t0 + 4832);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB312;
    goto LAB1;

LAB313:    *((unsigned int *)t14) = 1;
    goto LAB316;

LAB318:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB317;

LAB320:    t31 = (t0 + 4832);
    *((int *)t31) = 0;
    xsi_set_current_line(183, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(184, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(185, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2248);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(186, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2408);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(187, ng0);

LAB321:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB323;

LAB322:    t11 = (t0 + 4848);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB321;
    goto LAB1;

LAB323:    t13 = (t0 + 4848);
    *((int *)t13) = 0;
    xsi_set_current_line(187, ng0);

LAB324:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB328;

LAB326:    if (*((unsigned int *)t5) == 0)
        goto LAB325;

LAB327:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB328:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB330;

LAB329:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB332;

LAB331:    t29 = (t0 + 4864);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB324;
    goto LAB1;

LAB325:    *((unsigned int *)t14) = 1;
    goto LAB328;

LAB330:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB329;

LAB332:    t31 = (t0 + 4864);
    *((int *)t31) = 0;
    xsi_set_current_line(188, ng0);
    t2 = (t0 + 1048U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng2)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB334;

LAB333:    if (t19 != 0)
        goto LAB335;

LAB336:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB337;

LAB338:
LAB339:    xsi_set_current_line(191, ng0);
    t2 = (t0 + 1208U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng13)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB342;

LAB341:    if (t19 != 0)
        goto LAB343;

LAB344:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB345;

LAB346:
LAB347:    xsi_set_current_line(194, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(195, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(196, ng0);

LAB349:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB351;

LAB350:    t11 = (t0 + 4880);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB349;
    goto LAB1;

LAB334:    *((unsigned int *)t14) = 1;
    goto LAB336;

LAB335:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB336;

LAB337:    xsi_set_current_line(188, ng0);

LAB340:    xsi_set_current_line(189, ng0);
    xsi_vlogfile_write(1, 0, 0, ng3, 1, t0);
    xsi_set_current_line(189, ng0);
    xsi_vlog_stop(1);
    goto LAB339;

LAB342:    *((unsigned int *)t14) = 1;
    goto LAB344;

LAB343:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB344;

LAB345:    xsi_set_current_line(191, ng0);

LAB348:    xsi_set_current_line(192, ng0);
    xsi_vlogfile_write(1, 0, 0, ng14, 1, t0);
    xsi_set_current_line(192, ng0);
    xsi_vlog_stop(1);
    goto LAB347;

LAB351:    t13 = (t0 + 4880);
    *((int *)t13) = 0;
    xsi_set_current_line(196, ng0);

LAB352:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB356;

LAB354:    if (*((unsigned int *)t5) == 0)
        goto LAB353;

LAB355:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB356:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB358;

LAB357:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB360;

LAB359:    t29 = (t0 + 4896);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB352;
    goto LAB1;

LAB353:    *((unsigned int *)t14) = 1;
    goto LAB356;

LAB358:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB357;

LAB360:    t31 = (t0 + 4896);
    *((int *)t31) = 0;
    xsi_set_current_line(197, ng0);
    t2 = ((char*)((ng2)));
    t3 = (t0 + 1928);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(198, ng0);
    t2 = ((char*)((ng1)));
    t3 = (t0 + 2088);
    xsi_vlogvar_wait_assign_value(t3, t2, 0, 0, 1, 0LL);
    xsi_set_current_line(199, ng0);

LAB361:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB363;

LAB362:    t11 = (t0 + 4912);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB361;
    goto LAB1;

LAB363:    t13 = (t0 + 4912);
    *((int *)t13) = 0;
    xsi_set_current_line(199, ng0);

LAB364:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB368;

LAB366:    if (*((unsigned int *)t5) == 0)
        goto LAB365;

LAB367:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB368:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB370;

LAB369:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB372;

LAB371:    t29 = (t0 + 4928);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB364;
    goto LAB1;

LAB365:    *((unsigned int *)t14) = 1;
    goto LAB368;

LAB370:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB369;

LAB372:    t31 = (t0 + 4928);
    *((int *)t31) = 0;
    xsi_set_current_line(200, ng0);
    t2 = (t0 + 1208U);
    t3 = *((char **)t2);
    t2 = ((char*)((ng10)));
    memset(t14, 0, 8);
    t4 = (t3 + 4);
    t5 = (t2 + 4);
    t6 = *((unsigned int *)t3);
    t7 = *((unsigned int *)t2);
    t8 = (t6 ^ t7);
    t9 = *((unsigned int *)t4);
    t10 = *((unsigned int *)t5);
    t15 = (t9 ^ t10);
    t16 = (t8 | t15);
    t17 = *((unsigned int *)t4);
    t18 = *((unsigned int *)t5);
    t19 = (t17 | t18);
    t20 = (~(t19));
    t21 = (t16 & t20);
    if (t21 != 0)
        goto LAB374;

LAB373:    if (t19 != 0)
        goto LAB375;

LAB376:    t12 = (t14 + 4);
    t22 = *((unsigned int *)t12);
    t24 = (~(t22));
    t25 = *((unsigned int *)t14);
    t26 = (t25 & t24);
    t27 = (t26 != 0);
    if (t27 > 0)
        goto LAB377;

LAB378:
LAB379:    xsi_set_current_line(208, ng0);
    t2 = ((char*)((ng2)));
    memset(t14, 0, 8);
    xsi_vlog_signed_unary_minus(t14, 32, t2, 32);
    t3 = (t0 + 2888);
    xsi_vlogvar_wait_assign_value(t3, t14, 0, 0, 16, 0LL);
    xsi_set_current_line(209, ng0);

LAB381:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 != 0);
    if (t10 > 0)
        goto LAB383;

LAB382:    t11 = (t0 + 4944);
    *((int *)t11) = 1;
    t12 = (t0 + 4048U);
    *((char **)t12) = &&LAB381;
    goto LAB1;

LAB374:    *((unsigned int *)t14) = 1;
    goto LAB376;

LAB375:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;
    goto LAB376;

LAB377:    xsi_set_current_line(200, ng0);

LAB380:    xsi_set_current_line(201, ng0);
    xsi_vlogfile_write(1, 0, 0, ng15, 1, t0);
    xsi_set_current_line(201, ng0);
    xsi_vlog_stop(1);
    goto LAB379;

LAB383:    t13 = (t0 + 4944);
    *((int *)t13) = 0;
    xsi_set_current_line(209, ng0);

LAB384:    t2 = (t0 + 1608);
    t3 = (t2 + 56U);
    t4 = *((char **)t3);
    memset(t14, 0, 8);
    t5 = (t4 + 4);
    t6 = *((unsigned int *)t5);
    t7 = (~(t6));
    t8 = *((unsigned int *)t4);
    t9 = (t8 & t7);
    t10 = (t9 & 1U);
    if (t10 != 0)
        goto LAB388;

LAB386:    if (*((unsigned int *)t5) == 0)
        goto LAB385;

LAB387:    t11 = (t14 + 4);
    *((unsigned int *)t14) = 1;
    *((unsigned int *)t11) = 1;

LAB388:    t12 = (t14 + 4);
    t13 = (t4 + 4);
    t15 = *((unsigned int *)t4);
    t16 = (~(t15));
    *((unsigned int *)t14) = t16;
    *((unsigned int *)t12) = 0;
    if (*((unsigned int *)t13) != 0)
        goto LAB390;

LAB389:    t21 = *((unsigned int *)t14);
    *((unsigned int *)t14) = (t21 & 1U);
    t22 = *((unsigned int *)t12);
    *((unsigned int *)t12) = (t22 & 1U);
    t23 = (t14 + 4);
    t24 = *((unsigned int *)t23);
    t25 = (~(t24));
    t26 = *((unsigned int *)t14);
    t27 = (t26 & t25);
    t28 = (t27 != 0);
    if (t28 > 0)
        goto LAB392;

LAB391:    t29 = (t0 + 4960);
    *((int *)t29) = 1;
    t30 = (t0 + 4048U);
    *((char **)t30) = &&LAB384;
    goto LAB1;

LAB385:    *((unsigned int *)t14) = 1;
    goto LAB388;

LAB390:    t17 = *((unsigned int *)t14);
    t18 = *((unsigned int *)t13);
    *((unsigned int *)t14) = (t17 | t18);
    t19 = *((unsigned int *)t12);
    t20 = *((unsigned int *)t13);
    *((unsigned int *)t12) = (t19 | t20);
    goto LAB389;

LAB392:    t31 = (t0 + 4960);
    *((int *)t31) = 0;
    goto LAB1;

}


extern void work_m_01063943171425669689_2633127834_init()
{
	static char *pe[] = {(void *)Always_41_0,(void *)Initial_45_1};
	xsi_register_didat("work_m_01063943171425669689_2633127834", "isim/TEST_KIA_isim_beh.exe.sim/work/m_01063943171425669689_2633127834.didat");
	xsi_register_executes(pe);
}
