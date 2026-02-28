import java.time.LocalDate
import org.quantlib.{Date, Leg, Month, SimpleCashFlow}

@main
def test = {
  val today = LocalDate.now()
  val leg = new Leg()
  assert(leg.add(new SimpleCashFlow(
    123.45,
    new Date(today.getDayOfMonth(), Month.swigToEnum(today.getMonthValue()), today.getYear()),
  )))
  println(leg)
}
