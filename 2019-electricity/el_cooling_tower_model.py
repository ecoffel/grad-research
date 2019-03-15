import math


def coolingTowerEfficiency(t, rh, designT, designRH):
    P_cap = 1500
    P_ef = .3
    P_curtail = -1
    P_curtail_prc = -1

    Q_des = (1 - P_ef) / P_ef * P_cap

    p_a_des = 1013
    t_a_des = designT
    rh_a_des = designRH

    p_a_in = 1013
    t_a_in = t
    rh_a_in = rh

    p_a_out = 1013
    t_a_out = t
    rh_a_out = 100

    t_dp_a_des = 243.04 * (math.log(rh_a_des / 100) + ((17.625 * t_a_des) / (243.04 + t_a_des))) / (17.625 - math.log(rh_a_des / 100) - ((17.625 * t_a_des) / (243.04 + t_a_des)))
    sat_vp_a_des = 6.1078 * 10 ** (7.5 * t_dp_a_des / (t_dp_a_des + 237.3))
    vp_a_des = sat_vp_a_des * rh_a_des
    p_da_des = p_a_des - vp_a_des
    d_a_des = (p_da_des / (287.058 * (t_a_des + 273.15))) + (vp_a_des / (461.495 * (t_a_des + 273.15)))
    sh_a_des = vp_a_des / (8313.6 * t_a_des)
    h_a_des = 1.006 * t_a_des * sh_a_des * (1.84 * t_a_des + 2501)

    t_dp_a_in = 243.04 * (math.log(rh_a_in / 100) + ((17.625 * t_a_in) / (243.04 + t_a_in))) / (17.625 - math.log(rh_a_in / 100) - ((17.625 * t_a_in) / (243.04 + t_a_in)))
    sat_vp_a_in = 6.1078 * 10 ** (7.5 * t_dp_a_in / (t_dp_a_in + 237.3))
    vp_a_in = sat_vp_a_in * rh_a_in
    p_da_in = p_a_in - vp_a_in
    d_a_in = (p_da_in / (287.058 * (t_a_in + 273.15))) + (vp_a_in / (461.495 * (t_a_in + 273.15)))
    sh_a_in = vp_a_in / (8313.6 * t_a_in)
    h_a_in = 1.006 * t_a_in * sh_a_in * (1.84 * t_a_in + 2501)

    t_dp_a_out = 243.04 * (math.log(rh_a_out / 100) + ((17.625 * t_a_out) / (243.04 + t_a_out))) / (17.625 - math.log(rh_a_out / 100) - ((17.625 * t_a_out) / (243.04 + t_a_out)))
    sat_vp_a_out = 6.1078 * 10 ** (7.5 * (t_dp_a_out) / ((t_dp_a_out) + 237.3))
    vp_a_out = sat_vp_a_out * rh_a_out
    p_da_out = p_a_out - vp_a_out
    d_a_out = (p_da_out / (287.058 * (t_a_out + 273.15))) + (vp_a_out / (461.495 * (t_a_out + 273.15)))
    sh_a_out = vp_a_out / (8313.6 * t_a_out)
    h_a_out = 1.006 * t_a_out * sh_a_out * (1.84 * t_a_out + 2501)

    m_a = d_a_out - d_a_in
    m_a_des = d_a_out - d_a_des

    Q_cur_rej_des = -m_a_des * (h_a_out - h_a_des)
    Q_cur_rej = -m_a * (h_a_out - h_a_in)

    eff = min(Q_cur_rej / Q_cur_rej_des, 1)

    P_curtail = P_cap * eff
    P_curtail_prc = 1 - P_curtail / P_cap

    return (eff, P_curtail_prc)